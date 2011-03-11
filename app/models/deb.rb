# (c) 2008-2011 by Allgemeinbildung e.V., Bremen, Germany
# This file is part of Communtu.

# Communtu is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# Communtu is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero Public License for more details.

# You should have received a copy of the GNU Affero Public License
# along with Communtu.  If not, see <http://www.gnu.org/licenses/>.

# Ubuntu (Debian) packages in the Communtu repositories
# get objects in the database, such that creation of
# Ubuntu packages can be better monitored, and can be
# resumed independently of the process requiring the
# metapackage generation
# The class also provides methods for generation of
# debian packages and their upload into the Communtu
# repository using the tool reprepro.

# database fields: 
# derivative_id: derivative of the package
# distribution_id: distribution of the package
# errmsg: error message issued during package build
# generated: has the package successfully been generated?
# license_type: 0 = free, 1 = free or proprietary.
# log: relevant part of log/debianize.log
# metapackage_id: bundle for which this package is an instance
# outdated: is the package outdated?
# security_type: 0 = Ubuntu only, 1 = also Ubuntu community, 2 = also third-party.
# url: extended version, like 0.112-kubuntu-karmic-free-trusted (this field should be renamed...)
# version: short version, like 0.112

class Deb < ActiveRecord::Base
  belongs_to :metapackage
  belongs_to :distribution
  belongs_to :derivative

  require 'utils'

  # command for adding keys
  APT_KEY_COMMAND = "apt-key adv --recv-keys --keyserver"
  # command for adding packages to repository
  REPREPRO = "GNUPGHOME=/home/communtu/.gnupg reprepro -v -b #{RAILS_ROOT} --outdir #{RAILS_ROOT}/public/debs --confdir #{RAILS_ROOT}/debs --logdir #{RAILS_ROOT}/log --dbdir #{RAILS_ROOT}/debs/db --listdir #{RAILS_ROOT}/debs/list"

  def self.compute_codename(distribution,derivative,license,security)
    derivative.name.downcase+"-"+distribution.short_name.downcase+"-" +Package.license_components[license]+"-"+Package.security_components[security]
  end

  # get codename in the sense of reprepro
  def codename
    Deb.compute_codename(self.distribution,self.derivative,self.license_type,self.security_type)
  end

  # name of the debian package
  def name
    self.metapackage.debian_name
  end

  # names of components (in the sense of reprepro)
  def self.components
    [["main","universe","free"],["restricted","multiverse","non-free"]]
  end

  # names of packages we depend on
  def dependencies(arch)
    self.metapackage.package_names_for_deb(self.distribution,self.derivative,self.license_type,self.security_type,arch)
  end
  
  # generate debian package
  def generate(force=false)
    # already generated? then we are done (if we are not forced...)
    if self.generated and !force
      return
    end
    meta = self.metapackage
    dist = self.distribution
    der = self.derivative
    lic = self.license_type
    sec = self.security_type
    name = self.name
    codename = self.codename
    mlic = meta.compute_license_type
    msec = meta.compute_security_type
    version = "#{meta.version}-#{self.codename}"
    # compute list of packages contained in metapackage
    packages = {}
    plist = nil
    homogeneous = true
    Architecture.all.each do |arch|
      packages[arch] = self.dependencies(arch)
      if plist.nil? then
        plist = packages[arch]
      elsif plist != packages[arch] then
        homogeneous = false
      end
    end
    if homogeneous then
      architectures = [Architecture.find(:first)]
    else
      architectures = Architecture.all
    end
    # create a lock in order to avoid concurrent debianizations
    safe_system "dotlockfile -r 1000 #{RAILS_ROOT}/debs/lock"
    # do check again (since concurrent instance could have generated it in the meantime)
    if !(self.generated and !force)
      begin
        # logging
        f=File.open("#{RAILS_ROOT}/log/debianize.log","a")
        f.puts
        f.puts
        f.puts "++++++++++++++++++++++ Processing version #{name}-#{version}"
        f.puts Time.now
        f.puts
        f.puts "Included packages:"
        architectures.each do |arch|
           f.puts((if homogeneous then "" else arch.name+": " end)+packages[arch].join(", "))
        end
  
        # look for a version that does not exist yet
        v=1
        reprepro_call = "#{REPREPRO} listfilter #{codename} \"Package (== #{name}), Version (>= #{version+v.to_s})\""
        while !(out=IO.popen(reprepro_call,&:read)).empty?
          f.puts  "output of call\n #{reprepro_call}\nis: \in #{out}"
          reprepro_call = "#{REPREPRO} listfilter #{codename} \"Package (== #{name}), Version (>= #{version+v.to_s})\""
          v+=1
          if v>200 then
            break
          end
        end
        version += v.to_s
        f.close
  
        architectures.each do |arch|
          begin
            # build metapackage
            archname = if homogeneous then "all" else arch.name end
            debfile = Deb.makedeb(name,version,packages[arch],meta.description_english,dist,codename,Derivative.find(:first),[],false,archname)
  
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
            system "echo \"Uploading #{newfile}\" >> #{RAILS_ROOT}/log/debianize.log"
            safe_system "#{REPREPRO} -C #{component} includedeb #{codename} #{newfile} >> #{RAILS_ROOT}/log/debianize.log 2>&1"
            # remove package files, but not folder
            system "rm #{RAILS_ROOT}/debs/#{name}/#{name}* >/dev/null 2>&1 || true"
            # mark this deb as susccessfully generated
            self.generated = true
            self.errmsg = nil
            self.log = IO.popen("tail -n80 #{RAILS_ROOT}/log/debianize.log").read
            self.save
            # communtu repository has changed, hence clear apt-proxy cache
            system "sudo clear-apt-proxy-cache-communtu"
          rescue StandardError => err
            self.generated = false
            self.errmsg = err
            self.log = IO.popen("tail -n80 #{RAILS_ROOT}/log/debianize.log").read
            self.save
            meta.deb_error = true
            meta.save
          end
        end
        # was this the last deb to be generated for the bundle? Then mark bundle as updated
        if Deb.find(:first,:conditions => ["metapackage_id = ? and generated = ?",meta.id,false]).nil?
          meta.modified = false
          meta.debianizing = false
          meta.deb_error = false
          meta.save
        end
        rescue
          self.generated = false
          self.errmsg = "unknown"
          self.log = IO.popen("tail -n80 #{RAILS_ROOT}/log/debianize.log",&:read)
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
      end 
      # release lock
      safe_system "dotlockfile -u #{RAILS_ROOT}/debs/lock"
  end

  # generate debian package for installation of new sources
  def self.makedeb_for_source_install(name,version,description,packages,distribution,derivative,license,security,arch)
    #compute sources
    repos = Set.[]
    packages.each do |p|
      package_names   = []
      p.recursive_packages package_names, repos, distribution, arch, license, security
    end
    repos_a = repos.to_a
    Repository.close_deps(repos_a)
    repos = Set.new(repos_a)
    # only install sources, no packages
    codename = Deb.compute_codename(distribution,derivative,license,security)
    Deb.makedeb_lock(name,version,[],description,distribution,codename,derivative,repos,true,arch.name)
  end

  # create file 'control'
  def self.write_control(name,package_names,description,version = nil,archname = "all")
    f=File.open("control","w")
    if !version.nil? then
      f.puts "Package: #{name}"
      f.puts "Version: #{version}"
    end
    f.puts "Source: #{name}"
    f.puts "Section: metapackages"
    f.puts "Priority: Optional"
    f.puts "Maintainer: Communtu <info@communtu.org>"
    f.puts "Homepage: www.communtu.org"
    if version.nil? then
      f.puts
    end
    if version.nil? then
      f.puts "Package: #{name}"
    end
    f.puts "Architecture: #{archname}"
    if !package_names.empty? then
      f.puts "Depends: " + package_names.join(", ")
    end
    if description.nil? or description.empty? then
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

  # create a debian package, using lock to prevent concurrent makes
  def self.makedeb_lock(name,version,package_names,description,distribution,codename,derivative,repos,script,archname = "all")
    safe_system "dotlockfile -r 1000 #{RAILS_ROOT}/debs/lock"
    d = Deb.makedeb(name,version,package_names,description,distribution,codename,derivative,repos,script,archname)
    safe_system "dotlockfile -u #{RAILS_ROOT}/debs/lock"
    return d
  end

  # create a debian package
  def self.makedeb(name,version,package_names,description,distribution,codename,derivative,repos,script,archname = "all")
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
    Deb.write_control(name,package_names,description,nil,archname)

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
    if script
      # add repository for communtu at the end
      repos1 = repos.to_a.sort {|r1,r2| r1.url <=> r2.url}
      Deb.components.flatten.each do |component|
        repos1 << Repository.new(:url => "deb #{SETTINGS['repo']} "+codename, :subtype => component, :gpgkey => SETTINGS['repo_key'])
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
      f.puts ""
      f.puts "    set +e"
      f.puts "    grep -i #{distribution.short_name} /etc/*release"
      f.puts "    if [ \"$?\" != \"0\" ]; then"
    	f.puts "      echo 'Wrong distribution, expecting #{distribution.short_name}'"
      f.puts "      echo 'but found:'"
      f.puts "      cat /etc/*release"
      f.puts "      exit 1"
    	f.puts "    fi"
      f.puts "    set -e"
      f.puts ""
      f.puts '    KEYS="'+keys.select{|k| !k.empty?}.join('§')+'"'
      f.puts '    SOURCESKEYS="'+urls_keys.join('§')+'"'
      f.puts '    KEYSERVER="'+SETTINGS['key_server']+'"'
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
    archflag = if archname=="all" then "" else "-a#{archname}" end
    safe_system "dpkg-buildpackage #{archflag} -uc -us -rfakeroot >> #{RAILS_ROOT}/log/debianize.log 2>&1"
#    safe_system "dpkg-buildpackage -sgpg -k#{Deb::COMMUNTU_KEY} -rfakeroot >> #{RAILS_ROOT}/log/debianize.log 2>&1"
    Dir.chdir '../../..'
    # return filename of the newly created package
    return Dir.glob("debs/#{name}/#{name}_#{version}*#{archname}*deb")[0]
  end

  # remove packages whose distribution has vanished
  def self.clearvanished
    safe_system "#{RAILS_ROOT}/script/clearvanished"
  end

  # write reprepro configuration file
  def self.write_conf_distributions
    comps = Deb.components.flatten.join(" ")
    archs = Architecture.all.map{|a| a.name}.join(" ")
    f=File.open(RAILS_ROOT+'/debs/distributions','w')
    Derivative.all.each do |der|
      der.distributions.each do |dist|
        (0..1).each do |lic|
          (0..2).each do |sec|
            codename = Deb.compute_codename(dist,der,lic,sec)
            f.puts "Codename: #{codename}"
            f.puts "Origin: communtu"
            f.puts "Label: communtu"
            f.puts "Architectures: "+archs
            f.puts "Components: "+comps
            f.puts "Description: metapackages generated from communtu.de"
            f.puts "Contents: . .gz .bz2"
            f.puts "SignWith: #{SETTINGS['repo_key']}"
            f.puts 
          end
        end
      end
    end
    f.close
  end

  # compare versions of debian packages
  # note that this is a special ordering relation
  def self.version_gt(v1,v2)
    system('dpkg', '--compare-versions', v1, 'gt', v2)
  end

  # verify whether the stored deb is still correct
  def verify
    if self.metapackage.nil?
      puts "Deb #{self.id}: bundle with id #{self.metapackage_id} does not exist, destroying deb"
      self.destroy
      return nil
    end
    if self.distribution.nil?
      puts "Deb #{self.id}: distribution with id #{self.distribution_id} does not exist, destroying deb"
      self.destroy
      return nil
    end
    ok = true
    Architecture.all.each do |arch|
      res = verify_arch(arch)
      puts "Deb #{self.id}, bundle #{self.name}, arch #{arch.name}: #{res}"
      if res != "correct"
        ok = false
      end
    end
    if !ok then  # re-generate deb
      puts "Re-generating deb"
      self.generate(true)
    end
    return nil
  end
  
  def self.deb_get_dependencies(file)
    # extract control file
    system "ls -l #{file}"
    tmpdir = IO.popen("mktemp -d",&:read).chomp
    Dir.chdir tmpdir
    system "dpkg-deb -e #{file}"
    f=File.open("DEBIAN/control")
    Dir.chdir RAILS_ROOT
    # empty set of deps, in case there is no Depends: section
    deps = Set.[]
    # get dependencies from control file
    f.read.each do |line|
      if !(ind=line.index("Depends: ")).nil?
        line.chomp!
        deps = Set.new(line[ind+9,line.length].split(", "))
      end
    end
    f.close
    # cleanup
    system "rm -rf #{tmpdir}"
    return deps
  end

  def verify_arch(arch)
    # get position of deb file from reprepro
    f=IO.popen("#{REPREPRO} listfilter #{self.codename} \"Package (== #{self.name})\" | grep #{arch.name}")
    pos = f.read.chomp.split(" ")
    f.close
    if pos[1].nil? or pos[2].nil?
      return ("Reprepro could not find deb file")
    end
    filename_prefix = RAILS_ROOT + "/public/debs/pool/*/*/*/" + pos[1] + "*" + pos[2]
    file = Dir.glob(filename_prefix + "*all.deb")[-1]
    if file.nil?
      file = Dir.glob(filename_prefix + "*" + arch.name + ".deb")[-1]
    end
    if file.nil?
      return ("Could not find " + filename_prefix + "*"+ arch.name + ".deb")
    end
    needed_deps = Set.new(self.dependencies(arch))
    actual_deps = Deb.deb_get_dependencies(file)
    if actual_deps==needed_deps
      return "correct"
    else
      missing = needed_deps-actual_deps
      superfluous = actual_deps-needed_deps
      err = ""
      if !missing.empty?
        err += " Missing in deb file: "+missing.to_a.join(",")
      end
      if !superfluous.empty?
        err += " Superfluous in deb file: "+superfluous.to_a.join(",")
      end
      return err
    end
  end

  
  protected
  
# commented out, since it is not working (see #806)
#  def before_destroy
#     system "#{REPREPRO} remove #{self.codename} #{self.name}"
#  end
  
end
