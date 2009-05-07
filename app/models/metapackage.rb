class Metapackage < BasePackage

  require 'set.rb'
  require 'utils'
  
  has_many   :metacontents, :dependent => :destroy
  has_many   :comments, :dependent => :destroy
  has_many   :base_packages, :through => :metacontents
  has_many   :debs # destroy via callback
#  has_many   :packages, :through => :metacontents, :source => :base_package, :foreign_key => :base_package_id 
  belongs_to :category
  belongs_to :user
  
  validates_presence_of :name, :license_type, :user, :category # , :version, :description
  
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

  # contained packages (without bundles)
  def packages
    base_packages.select{|p| p.class == Package}
  end
  
  # metapackages using this one
  def metapackages
    Metapackage.find(:all,:conditions => ["metacontents.base_package_id = ?",self.id], :include => :metacontents)
  end

  #immediate conflicts within the bundle
  def immediate_conflicts
    all_cons = {}
    packages = self.packages
    packages.each do |p|
      cons = p.conflicts & packages
      if !cons.empty? then
        all_cons[p]=cons
      end
    end
    return all_cons
  end

  #conflicts within the bundle
  def conflicts
    all_cons = {}
    packages = self.all_recursive_packages
    packages.each do |p|
      cons = p.conflicts & packages
      if !cons.empty? then
        all_cons[p]=cons
      end
    end
    return all_cons
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

  def recursive_packages_sources package_sources, dist, license, security
    self.base_packages.each do |p|
        if p.class == Package
            reps = p.repositories_dist(dist).select{|r| r.security_type<=security && r.license_type<=license}
            if !reps.empty? then
              reps.each do |rep|
                if package_sources[rep].nil? then
                  package_sources[rep] = [p]
                else  
                  package_sources[rep] << p
                end
              end
            end
        else
            p.recursive_packages_sources package_sources, dist, license, security
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
    Metapackage.makedeb(name,version,[],description,codename,derivative,repos)
  end 

  def self.makedeb(name,version,package_names,description,codename,derivative,repos)
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
    if description.empty? then
      lines = ["communtu metapackage (no further description)"]
    else
      #replace empty lines by "."
      lines = description.gsub(/\r/,"").split("\n").map do |l|
        if l.gsub(/ \t/,"").empty? then "." else l end
      end
    end
    #start each new line with two spaces
    f.puts "Description: " + lines.join("\n  ")
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
        if derivative.dialog == "zenity" then
          urls_keys << url+"*"+key
        else  
          urls_keys << url+"\t"+key
        end  
      end
      # create  'preinst'
      # first half of standard script ...
      safe_system "cp ../../../preinst1 preinst"
      # ... handling of new sources and keys ...
      f=File.open("preinst","a")
      f.puts '    SOURCES="'+urls.join('*')+'"'
      f.puts '    KEYS="'+keys.select{|k| !k.empty?}.join('*')+'"'
      if derivative.dialog == "zenity" then
        f.puts '    SOURCESKEYS="'+urls_keys.join('*')+'"'
        f.close
        safe_system "cat ../../../preinst2-zenity >> preinst"
      else  
        f.puts '    SOURCESKEYS="'+urls_keys.join('\\n')+'"'
        f.close
        safe_system "cat ../../../preinst2-kdialog >> preinst"
      end  
      # ... and main part of standard script
      safe_system "cat ../../../preinst3 >> preinst"
    end  

    # build deb package
    Dir.chdir '..'
    safe_system "dpkg-buildpackage -uc -us -rfakeroot >> #{RAILS_ROOT}/log/debianize.log 2>&1" 
#    safe_system "dpkg-buildpackage -sgpg -kD66AFBC0 -rfakeroot >> #{RAILS_ROOT}/log/debianize.log 2>&1"
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
    # only proceed if there is a new version
    if self.version != self.debianized_version
      # record verison
      self.debianized_version = self.version
      self.save
      description = self.description
      # generate debs
      Distribution.all.each do |dist|
        Derivative.all.each do |der|
          (0..1).each do |lic|
            (0..2).each do |sec|
              codename = Metapackage.codename(dist,der,lic,sec)
              version = "#{self.version}-#{codename}1"
              deb = Deb.create({:metapackage_id => self.id, :distribution_id => dist.id, :derivative_id => der.id, 
                                :license_type => lic, :security_type => sec, :version => self.version,
                                :url => version, :generated => false})
            end
          end
        end
      end  
      # generate debian packages from debs
      Deb.find(:all,:conditions => ["metapackage_id = ? and version = ?",self.id,self.version]).each do |deb|
        deb.generate
      end
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
    
  protected
  
  # :dependent => :destroy will not work since the metapackage is needed for destroying the debs
  def before_destroy
    Deb.destroy(self.debs.map{|d| d.id})
  end
  
end
