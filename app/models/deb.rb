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
  REPREPRO = "reprepro -v -b #{RAILS_ROOT} --outdir public/debs --confdir debs --logdir log --dbdir debs/db --listdir debs/list"

  def codename
    Metapackage.codename(self.distribution,self.derivative,self.license_type,self.security_type)
  end

  def name
    self.metapackage.debian_name
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
      # compute list of packages contained in metapackage (todo: delegate this to an own method, preferably using more :includes)
      mcs = Metacontent.find(:all,:conditions => 
             ["metapackage_id = ? and metacontents_distrs.distribution_id = ? and metacontents_derivatives.derivative_id = ?",
              meta.id,dist.id,der.id],:include => [:metacontents_distrs, :metacontents_derivatives])
      packages = mcs.map{|mc| mc.base_package}.select{|p| p.is_present(dist,lic,sec)}.map{|p| p.debian_name}
      f.puts "Included packages:"
      f.puts packages.join(", ")
      f.close
      
      begin
        # build metapackage
        debfile = Metapackage.makedeb(name,version,packages,meta.description,codename,Derivative.find(:first),[])
  
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
            codename = Metapackage.codename(dist,der,lic,sec)
            f.puts "Codename: #{codename}"
            f.puts "Origin: communtu"
            f.puts "Label: communtu"
            f.puts "Architectures: i386 amd64"
            f.puts "Components: "+Metapackage.components.flatten.join(" ")
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
