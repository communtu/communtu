class Deb < ActiveRecord::Base
  belongs_to :metapackage
  belongs_to :distribution
  belongs_to :derivative

  require 'utils'

  # command for adding keys
  APT_KEY_COMMAND = "apt-key adv --recv-keys --keyserver"
  KEYSERVER = "wwwkeys.eu.pgp.net"
  # communtu repository
  COMMUNTU_REPO = "http://packages.communtu.de"
  COMMUNTU_KEY = "D66AFBC0"
  # command for uploading debs to repository
  REPREPRO = "GNUPGHOME=/home/communtu/.gnupg reprepro -v -b #{RAILS_ROOT} --outdir public/debs --confdir debs --logdir log --dbdir debs/db --listdir debs/list"

  def self.compute_codename(distribution,derivative,license,security)
    derivative.name.downcase+"-"+distribution.short_name.downcase+"-" +Package.license_components[license]+"-"+Package.security_components[security]
  end


  def codename
    Deb.compute_codename(self.distribution,self.derivative,self.license_type,self.security_type)
  end

  def name
    self.metapackage.debian_name
  end

  def self.components
    [["main","universe","free"],["restricted","multiverse","non-free"]]
  end

  # generate debian package
  def generate
    # create a lock in order to avoid concurrent debianizations
    safe_system "dotlockfile #{RAILS_ROOT}/debs/lock"
    begin
      meta = self.metapackage
      dist = self.distribution
      der = self.derivative
      lic = self.license_type
      sec = self.security_type
      name = self.name
      codename = self.codename
      mlic = meta.compute_license_type
      msec = meta.compute_security_type
      version = "#{meta.version}-#{self.codename}1"
      f=File.open("#{RAILS_ROOT}/log/debianize.log","a")
      f.puts
      f.puts
      f.puts "++++++++++++++++++++++ Processing version #{name}-#{version}"
      f.puts Time.now
      f.puts
      # compute list of packages contained in metapackage 
      packages = package_names_for_deb(dist,der,lic,sec)
      f.puts "Included packages:"
      f.puts packages.join(", ")
      f.close
      
      begin
        # build metapackage
        debfile = Deb.makedeb(name,version,packages,meta.description,codename,Derivative.find(:first),[])
  
        # make name of .deb unique by adding the codename
        # newfile = debfile.gsub("_all.deb","~"+codename+"_all.deb")
        # safe_system "mv #{debfile} #{newfile}"
        newfile = debfile

        # what license types and security types are actually used in the bundle?
        # use this info to determine the component
        component = Deb.components[[lic,mlic].min][[sec,msec].min]
        # upload metapackage
        # todo: make name of .deb unique
        puts "Uploading #{newfile}"
        safe_system "#{REPREPRO} -C #{component} includedeb #{codename} #{newfile} >> #{RAILS_ROOT}/log/debianize.log 2>&1"
        # remove package files, but not folder
        safe_system "rm #{RAILS_ROOT}/debs/#{name}/#{name}* >/dev/null 2>&1 || true"
        # mark this deb as susccessfully generated
        self.generated = true
        self.errmsg = nil
        self.log = IO.popen("tail -n80 #{RAILS_ROOT}/log/debianize.log").read
        self.save
        # was this the last deb to be generated for the bundle? Then mark bundle as updated
        if Deb.find(:first,:conditions => ["metapackage_id = ? and generated = ?",meta.id,false]).nil?
          meta.modified = false
          meta.debianizing = false
          meta.deb_error = false
          meta.save
        end
      rescue StandardError => err
        self.generated = false
        self.errmsg = err
        self.log = IO.popen("tail -n80 #{RAILS_ROOT}/log/debianize.log").read
        self.save
        meta.deb_error = true
        meta.save
      end
    rescue 
      self.generated = false
      self.errmsg = "unknown"
      self.log = IO.popen("tail -n80 #{RAILS_ROOT}/log/debianize.log").read
      self.save
      meta.deb_error = true
      meta.save
      f=File.open("#{RAILS_ROOT}/log/debianize.log","a")
      f.puts
      f.puts "Debianizing #{name} failed! (id = #{id})"
      f.puts
      f.close
    end  
    # cleanup
    system "rm -r #{RAILS_ROOT}/debs/#{name}*"
    # release lock
    safe_system "dotlockfile -u #{RAILS_ROOT}/debs/lock"
  end

  def self.makedeb_for_source_install(name,version,description,packages,distribution,derivative,license,security)
    #compute sources
    repos = Set.[]
    packages.each do |p|
      package_names   = []
      p.recursive_packages package_names, repos, distribution, license, security
    end
    # only install sources, no packages
    codename = Deb.codename(distribution,derivative,license,security)
    Deb.makedeb(name,version,[],description,codename,derivative,repos)
  end

  # create file 'control'
  def self.write_control(name,package_names,description,version = nil)
    f=File.open("control","w")
    f.puts "Package: #{name}"
    if !version.nil? then
      f.puts "Version: #{version}"
    end
    f.puts "Source: #{name}"
    f.puts "Section: metapackages"
    f.puts "Priority: Optional"
    f.puts "Maintainer: Communtu <info@communtu.de>"
    f.puts "Homepage: www.communtu.de"
    f.puts
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
    Deb.write_control(name,package_names,description)

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
      Deb.components.flatten.each do |component|
        repos1 << Repository.new(:url => "deb #{Deb::COMMUNTU_REPO} "+codename, :subtype => component, :gpgkey => Deb::COMMUNTU_KEY)
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
        urls_keys << url+"+"+key
      end
      # create  'preinst'
      # first half of standard script ...
      safe_system "cp ../../../preinst1 preinst"
      # ... handling of new sources and keys ...
      f=File.open("preinst","a")
      f.puts '    KEYS="'+keys.select{|k| !k.empty?}.join('§')+'"'
      f.puts '    SOURCESKEYS="'+urls_keys.join('§')+'"'
      f.puts '    KEYSERVER="'+Deb::KEYSERVER+'"'
      f.close
      # ... selection of sources according to sources.list
      safe_system "cat ../../../preinst2 >> preinst"
      if derivative.dialog == "zenity" then
        safe_system "cat ../../../preinst2-zenity >> preinst"
      else
        safe_system "cat ../../../preinst2-kdialog >> preinst"
      end
      # ... and main part of standard script
      safe_system "cat ../../../preinst3 >> preinst"
    end

    # build deb package
    Dir.chdir '..'
    safe_system "echo >>  #{RAILS_ROOT}/log/debianize.log 2>&1"
    safe_system "date >>  #{RAILS_ROOT}/log/debianize.log 2>&1"
    safe_system "dpkg-buildpackage -uc -us -rfakeroot >> #{RAILS_ROOT}/log/debianize.log 2>&1"
#    safe_system "dpkg-buildpackage -sgpg -k#{Deb::COMMUNTU_KEY} -rfakeroot >> #{RAILS_ROOT}/log/debianize.log 2>&1"
    Dir.chdir '../../..'
    # return filename of the newly created package
    return Dir.glob("debs/#{name}/#{name}_#{version}*deb")[0]
  end

  # remove packages whose distribution has vanished
  def self.clearvanished
    safe_system "#{REPREPRO} --delete clearvanished"
  end
  
  def self.write_conf_distributions
    f=File.open(RAILS_ROOT+'/debs/distributions','w')
    Distribution.all.each do |dist|
      Derivative.all.each do |der|
        (0..1).each do |lic|
          (0..2).each do |sec|
            codename = Deb.codename(dist,der,lic,sec)
            f.puts "Codename: #{codename}"
            f.puts "Origin: communtu"
            f.puts "Label: communtu"
            f.puts "Architectures: i386 amd64"
            f.puts "Components: "+Deb.components.flatten.join(" ")
            f.puts "Description: metapackages generated from communtu.de"
            f.puts "SignWith: #{COMMUNTU_KEY}"
            f.puts 
          end
        end
      end
    end
    f.close
  end

  def self.version_gt(v1,v2)
    system('dpkg', '--compare-versions', v1, 'gt', v2)
  end
  
  protected
  
  def before_destroy
    safe_system "#{REPREPRO} remove #{self.codename} #{self.name}"
  end
  
end
