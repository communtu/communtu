class Metapackage < BasePackage

  require 'set.rb'
  
  has_many   :metacontents, :dependent => :destroy
  has_many   :comments, :dependent => :destroy
  has_many   :base_packages, :through => :metacontents
#  has_many   :packages, :through => :metacontents, :source => :base_package, :foreign_key => :base_package_id 
  belongs_to :category
  belongs_to :user
  
  validates_presence_of :name, :license_type, :user, :category
  
  @state = { :pending => 0, :published => 1, :rejected => 2 }
  @levels = [ "gar nicht", "normal", "erweitert", "Experte", "Freak" ]
  
  def self.state
    @state
  end
  
  def self.levels
    @levels
  end

  def owned_by? user
    (user_id == user.id)
  end
  
  def is_published?
    return self.published == Metapackage.state[:published]
  end
  
  # copy the metapackage contents from from_dist to to_dist
  def migrate(from_dist, to_dist)
    not_found = []
    self.metacontents.each do |mc|
      # look for the mcs belonging to from_dist
      # *and* having packages available for to_dist
      if mc.distributions.include?(from_dist)
        if mc.base_package.class != Package 
          # bundle, always append it
          append = true
        else
          # package, only append it if present in the distribution
          if mc.base_package.distributions.include?(to_dist)
            append = true
          else
            not_found << mc.base_package
            append = false
          end
        end
        if append && !mc.distributions.include?(to_dist)
          mc.distributions << to_dist
        end
      end
    end
    return not_found    
  end
  
  # icon for bundles
  def self.icon(size)
    s = size.to_s
    return '<img border="0" height="'+s+'" width="'+s+'" src="/images/apps/Metapackage.png"/>'
  
  end

  # convert rating to new default_install field
  def convert_rating
    self.default_install = (!rating.nil?) && rating<=1
    self.save
  end

## installation and creating debian metapackages

  def self.codename(distribution,derivative)
    "#{derivative.name.downcase}-#{distribution.short_name.downcase}"
  end
  
  def recursive_packages package_names, package_sources, dist, license, security
    self.base_packages.each do |p|
        if p.class == Package
            reps = p.repositories_dist(dist).select{|r| r.security_type<=security && r.license_type<=license}
            if !reps.empty? then
              package_names.push(p.name)
              reps.each do |rep|
                package_sources.add(rep)
              end
            end
        else
            p.recursive_packages package_names, package_sources, dist, license, security
        end
    end
  end

  def self.makedeb_for_source_install(name,version,description,packages,distribution,derivative,license,security)
    #compute sources
    repos = Set.[]
    packages.each do |p|    
      package_names   = []
      p.recursive_packages package_names, repos, distribution, license, security
    end
    # only install sources, no packages
    Metapackage.makedeb(name,version,[],description,distribution,derivative,repos)
  end 
  
  #free native = main
  #free trusted = universe
  #free third-party = free
  #nonfree native = restricted
  #nonfree trusted = multiverse
  #nonfree third-party = nonfree
  
  def self.makedeb(name,version,package_names,description,distribution,derivative,repos)
    Dir.chdir RAILS_ROOT+'/debs'
    if !File.exists?(name)
      Dir.mkdir name
    end
    Dir.chdir name
    nameversion = name+"-"+version
    if !File.exists?(nameversion)
      Dir.mkdir nameversion
    end  
    Dir.chdir nameversion
    #  simulate the commands:
    #    system 'dh_make --email "info@communtu.de" --copyright gpl --single --createorig --packagename ' + pname
    #    system 'rm -f docs dirs README.Debian *.ex *.EX'
    # todo: adapt changelog according to difference in package list
    if !File.exists?('debian')
      Dir.mkdir 'debian'
      Dir.chdir 'debian'
      # copy file 'copyright'
      system "cp ../../../copyright ."
      # copy file 'rules'
      system "cp ../../../rules ."
      # copy file 'compat'
      system "cp ../../../compat ."
    else  
      Dir.chdir 'debian'
    end  

    # create file 'control'
    f=File.open("control","w")
    f.puts "Source: #{name}"
    f.puts "Section: metapackages"
    f.puts "Priority: Optional"
    f.puts "Maintainer: Communtu <info@communtu.de>"
    f.puts "Homepage: www.communtu.de"
    f.puts
    f.puts "Package: #{name}"
    f.puts "Architecture: all"
    f.puts "Depends: " + package_names.join(", ")
    # todo: better formatting of description
    f.puts "Description: " + description.gsub(/\n/,"\n  ").gsub(/\r/,"")

    f.close

    # create file 'changelog'
    f=File.open("changelog","w")
    f.puts "#{name} (#{version}) #{Metapackage.codename(distribution,derivative)}; urgency=low"
    f.puts
    f.puts "  * Initial release"
    f.puts
    f.puts " -- Communtu <info@communtu.de>  "+Time.now.strftime("%a, %d %b %Y %H:%M:%S")+" +0100"
    f.puts
    f.close

    # create maintainer scripts
    if !repos.empty?
      # add repository for communtu at the end
      # todo: add key for communtu package server
      repos1 = repos.to_a.sort {|r1,r2| r1.url <=> r2.url}
      repos1 << Repository.new(:url => "deb http://communtu.bremer-commune.dyndns.org/debs", :subtype => "./")
      # get urls and keys
      urls = []
      keys = []
      urls_keys = []
      repos1.each do |repository|
        url = repository.url + " " + repository.subtype
        key = repository.gpgkey
        if key.nil? then key = "" end
        urls << url
        keys << key
        urls_keys << url+"*"+key
      end
      # create  'preinst'
      # first half of standard script ...
      system "cp ../../../preinst1 preinst"
      # ... addition of new sources and keys ...
      f=File.open("preinst","a")
      f.puts '    SOURCES="'+urls.join('*')+'"'
      f.puts '    KEYS="'+keys.select{|k| !k.empty?}.join('*')+'"'
      f.puts '    SOURCESKEYS="'+urls_keys.join('*')+'"'
      f.close
      # ... and second half of standard script
      system "cat ../../../preinst2 >> preinst"
    end  

    # build deb package
    Dir.chdir '..'
    system "dpkg-buildpackage -uc -us -rfakeroot"
    Dir.chdir '../../..'
    # return filename of the newly created package
    return Dir.glob("debs/#{name}/#{name}_#{version}*deb")[0]
  end

  def debianize
    # start with version 0.1 if there is none
    if self.version.nil? or self.version.empty? then
      self.version = "0.1"
      self.save
    end
    # is someone else already debianizing this metapackage?
    if Dir.glob("#{self.debian_name}*").empty?
      version = self.version
      description = self.description
      Distribution.all.each do |dist|
        Derivative.all.each do |der|
          (0..1).each do |lic|
            (0..2).each do |sec|
              component = Package.license_components[lic]+"-"+Package.security_components[sec]
              codename = Metapackage.codename(dist,der)
              name = self.debian_name+"-"+component
              # compute list of packages contained in metapackage (todo: delegate this to an own method, preferably using more :includes)
              mcs = Metacontent.find(:all,:conditions => 
                     ["metapackage_id = ? and metacontents_distrs.distribution_id = ? and metacontents_derivatives.derivative_id = ?",
                      self.id,dist.id,der.id],:include => [:metacontents_distrs, :metacontents_derivatives])
              packages = mcs.map{|mc| mc.base_package}.select{|p| p.is_present(dist,lic,sec)}.map{|p| p.debian_name+"-"+component}
              # build metapackage
              debfile = Metapackage.makedeb(name,version,packages,description,dist,der,[])
              # upload metapackage
              # todo: make name of .deb unique
              system "reprepro -v -b #{RAILS_ROOT} --outdir public/debs --confdir debs --logdir log --dbdir debs/db --listdir debs/list -C #{component} includedeb #{codename} #{debfile}"
              # remove package files, but not folder
              system "rm #{RAILS_ROOT}/debs/#{name}/#{name}* || true"
            end
          end
        end
      end
      # cleanup
      system "rm -r #{RAILS_ROOT}/debs/#{self.debian_name}*"
    end
  end
  
  def self.debianize_all
    Metapackage.all.each do |m|
      puts m.name
      m.debianize
    end
  end 
  
end
