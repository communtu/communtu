class Metapackage < BasePackage

  require 'set.rb'
  require 'utils'
  
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

  # this function is needed to complement is_present for class Package
  def is_present(distribution,licence,security)
    true
  end

  def compute_license_type
    (self.base_packages.map{|p| p.compute_license_type} <<0).max
  end
  
  def compute_security_type
    (self.base_packages.map{|p| p.compute_security_type} <<0).max
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

  def self.codename(distribution,derivative,license,security)
    derivative.name.downcase+"-"+distribution.short_name.downcase+"-" +Package.license_components[license]+"-"+Package.security_components[security]
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
    codename = Metapackage.codename(distribution,derivative,license,security)
    Metapackage.makedeb(name,version,[],description,codename,repos)
  end 

  def self.makedeb(name,version,package_names,description,codename,repos)
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
      safe_system "cp ../../../copyright ."
      # copy file 'rules'
      safe_system "cp ../../../rules ."
      # copy file 'compat'
      safe_system "cp ../../../compat ."
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
    if !package_names.empty? then
      f.puts "Depends: " + package_names.join(", ")
    end  
    # todo: better formatting of description
    if description.empty? then
      f.puts "Description: communtu metapackage (no further description)"
    else
      d = description.gsub(/\n/,"\n  ").gsub(/\r/,"")
      while (newd=d.gsub(/\n\n/,"\n"))!=d
        d = newd
      end
      f.puts "Description: " + newd
    end
    f.close

    # create file 'changelog'
    f=File.open("changelog","w")
    f.puts "#{name} (#{version}) #{codename}; urgency=low"
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
      Metapackage.components.flatten.each do |component|
        repos1 << Repository.new(:url => "deb http://packages.communtu.de "+codename, :subtype => component)
      end
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
      safe_system "cp ../../../preinst1 preinst"
      # ... addition of new sources and keys ...
      f=File.open("preinst","a")
      f.puts '    SOURCES="'+urls.join('*')+'"'
      f.puts '    KEYS="'+keys.select{|k| !k.empty?}.join('*')+'"'
      f.puts '    SOURCESKEYS="'+urls_keys.join('*')+'"'
      f.close
      # ... and second half of standard script
      safe_system "cat ../../../preinst2 >> preinst"
    end  

    # build deb package
    Dir.chdir '..'
    safe_system "dpkg-buildpackage -uc -us -rfakeroot"
    Dir.chdir '../../..'
    # return filename of the newly created package
    return Dir.glob("debs/#{name}/#{name}_#{version}*deb")[0]
  end

  def self.components
    [["main","universe","free"],["restricted","multiverse","non-free"]]
  end
  
  def debianize
    # start with version 0.1 if there is none
    if self.version.nil? or self.version.empty? then
      self.version = "0.1"
      self.save
    end
    # is someone else already debianizing this metapackage?
    if Dir.glob("#{self.debian_name}*").empty?
      mlic = self.compute_license_type
      msec = self.compute_security_type
      description = self.description
      Distribution.all.each do |dist|
        Derivative.all.each do |der|
          (0..1).each do |lic|
            (0..2).each do |sec|
              codename = Metapackage.codename(dist,der,lic,sec)
              name = self.debian_name
              version = "#{self.version}-#{codename}1"
              puts
              puts
              puts "++++++++++++++++++++++ Processing version #{name}-#{version}"
              puts
              # compute list of packages contained in metapackage (todo: delegate this to an own method, preferably using more :includes)
              mcs = Metacontent.find(:all,:conditions => 
                     ["metapackage_id = ? and metacontents_distrs.distribution_id = ? and metacontents_derivatives.derivative_id = ?",
                      self.id,dist.id,der.id],:include => [:metacontents_distrs, :metacontents_derivatives])
              packages = mcs.map{|mc| mc.base_package}.select{|p| p.is_present(dist,lic,sec)}.map{|p| p.debian_name}
              # build metapackage
              debfile = Metapackage.makedeb(name,version,packages,description,codename,[])

              # make name of .deb unique by adding the codename
              # newfile = debfile.gsub("_all.deb","~"+codename+"_all.deb")
              # safe_system "mv #{debfile} #{newfile}"
              newfile = debfile

              # what license types and security types are actually used in the bundle?
              # use this info to determine the component
              component = Metapackage.components[[lic,mlic].min][[sec,msec].min]
              # upload metapackage
              # todo: make name of .deb unique
              puts "Uploading #{newfile}"
              safe_system "reprepro -v -b #{RAILS_ROOT} --outdir public/debs --confdir debs --logdir log --dbdir debs/db --listdir debs/list -C #{component} includedeb #{codename} #{newfile}"
              # remove package files, but not folder
              safe_system "rm #{RAILS_ROOT}/debs/#{name}/#{name}* >/dev/null 2>&1 || true"
            end
          end
        end
      end
      # cleanup
      safe_system "rm -r #{RAILS_ROOT}/debs/#{self.debian_name}*"
    end
  end
  
  def self.debianize_all
    Metapackage.all.each do |m|
      puts
      puts
      puts "++++++++++++++++++++++ Processing package #{m.name}"
      puts
      m.debianize
    end
  end 
  
  def self.write_conf_distributions
    f=File.open(RAILS_ROOT+'/debs/distributions','w')
    Distribution.all.each do |dist|
      Derivative.all.each do |der|
        (0..1).each do |lic|
          (0..2).each do |sec|
            codename = Metapackage.codename(dist,der,lic,sec)
            f.puts "Codename: #{codename}"
            f.puts "Origin: communtu"
            f.puts "Label: communtu"
            f.puts "Architectures: i386 amd64"
            f.puts "Components: "+Metapackage.components.flatten.join(" ")
            f.puts "Description: metapackages generated from communtu.de"
            f.puts "#SignWith: yes"
            f.puts 
          end
        end
      end
    end
    f.close
  end
  
end
