# each liveCD is stored in the database as an object of class Livecd
# this allows for better error logging and recovery
# note that the iso itself is stored in the file system, however

require "lib/utils.rb"

class Livecd < ActiveRecord::Base
  belongs_to :distribution
  belongs_to :derivative
  belongs_to :architecture
  belongs_to :metapackage
  has_many :livecd_users, :dependent => :destroy
  has_many :users, :through => :livecd_users
  validates_presence_of :name, :distribution, :derivative, :architecture

  # version of liveCD, made from derivative, distribution, architecture, license and security
  def smallversion
    self.derivative.name.downcase+"-" \
    +(self.distribution.name.gsub(/[a-zA-Z ]/,'')) \
    +"-desktop-"+self.architecture.name
  end

  def fullversion
    self.smallversion \
    + "-" +(Package.license_components[self.license_type]) \
    + "-" +(Package.security_components[self.security_type])
  end

  # unique name of liveCD
  def fullname
    "#{self.name}-#{self.fullversion}"
  end

  # filename of LiveCD in the file system
  def iso_image
    "#{RAILS_ROOT}/public/isos/#{self.fullname}.iso"
  end

  # filename of kvm image in the file system
  def kvm_image
      "#{RAILS_ROOT}/public/isos/#{self.fullname}.kvm.img"
  end

  # filename of kvm image in the file system
  def usb_image
    "#{RAILS_ROOT}/public/isos/#{self.fullname}.usb.img"
  end

  def self.rails_url
    if RAILS_ROOT.index("test").nil?
      then "http://communtu.org"
      else "http://test.communtu.de"
    end
  end
  # base url of LiveCD on the communtu server
  def base_url
    return "#{Livecd.rails_url}/isos/#{self.fullname}"
  end

  # url of iso image on the communtu server
  def iso_url
    "#{self.base_url}.iso"
  end

  # url of kvm image on the communtu server
  def kvm_url
    "#{self.base_url}.kvm.img"
  end

  # url of usb image on the communtu server
  def usb_url
    "#{self.base_url}.usb.img"
  end

  # check if a user supplied name is acceptable
  def self.check_name(name)
    if name.match(/^communtu-.*/)
      return I18n.t(:livecd_communtu_name)
    end
    if name.match(/^[A-Za-z0-9_-]*$/).nil?
      return I18n.t(:livecd_incorrect_name)
    end
    if !Livecd.find_by_name(name).nil?
      return I18n.t(:livecd_existing_name)
    end
    return nil
  end

  def worker
    MiddleMan.new_worker(:class => :livecd_worker,
                     :args => self.id,
                     :job_key => :livecd_worker,
                     :singleton => true)
  end
  
  # create the liveCD in a forked process
  def fork_remaster(port=2222)
      nice = (self.users[0].nil? or !self.users[0].has_role?('administrator'))
      nicestr = if nice then "nice -n +10 " else "" end
      self.pid = fork do
            ActiveRecord::Base.connection.reconnect!
	 	        system "echo \"Livecd.find(#{self.id.to_s}).remaster(#{port.to_s})\" | #{nicestr} nohup script/console production"
      end
      ActiveRecord::Base.connection.reconnect!
      self.save
  end

  # created liveCD, using script/remaster
  def remaster(port=2222)
    ActiveRecord::Base.connection.reconnect!
    ver = self.smallversion
    fullname = self.fullname
    # need to generate iso, use lock in order to prevent parallel generation of multiple isos
    begin
        safe_system "dotlockfile -p -r 1000 #{RAILS_ROOT}/livecd#{port}_lock"
        self.generating = true
        self.save
        # log to log/livecd.log
        system "(echo; echo \"------------------------------------\")  >> #{RAILS_ROOT}/log/livecd#{port}.log"
        call = "(echo \"Creating live CD #{fullname}\"; date) >> #{RAILS_ROOT}/log/"
        system (call+"livecd#{port}.log")
        system (call+"livecd#{port}.short.log")
        # check if there is enough disk space (at least 25 GB)
        while disk_free_space(SETTINGS['iso_path']) < 25000000000
          # destroy the oldest liveCD
          cd=Livecd.find(:first,:order=>"created_at ASC")
          call = "(echo \"Disk full - deleting live CD #{cd.id}\" >> #{RAILS_ROOT}/log/"
          system (call+"livecd#{port}.log")
          system (call+"livecd#{port}.short.log")
          cd.destroy
        end
        # normal users get nice'd
        nice = (self.users[0].nil? or !self.users[0].has_role?('administrator'))
        nicestr = if nice then "-nice " else "" end
        # Jaunty and lower need virtualisation due to requirement of sqaushfs version >= 4 (on the server, we have Hardy)
        if self.distribution_id < 5 then
          virt = "-v "
        else
          virt = ""
        end
        isoflag = self.iso ? "-iso #{self.iso_image} " : ""
        kvmflag = self.kvm ? "-kvm #{self.kvm_image} " : ""
        usbflag = self.usb ? "-usb #{self.usb_image} " : ""
        remaster_call = "#{RAILS_ROOT}/script/remaster create #{nicestr}#{virt}#{isoflag}#{kvmflag}#{usbflag}#{ver} #{self.name} #{self.srcdeb} #{self.installdeb} #{port} >> #{RAILS_ROOT}/log/livecd#{port}.log 2>&1"
        system "echo \"#{remaster_call}\" >> #{RAILS_ROOT}/log/livecd#{port}.log"
        self.failed = !(system remaster_call)
        # kill VM and release lock, necessary in case of abrupt exit
        system "sudo kill-kvm #{port}"
        system "dotlockfile -u /home/communtu/livecd/livecd#{port}.lock"
        system "echo  >> #{RAILS_ROOT}/log/livecd#{port}.log"
        call = "echo \"finished at:\"; date >> #{RAILS_ROOT}/log/"
        system (call+"livecd#{port}.log")
        system (call+"livecd#{port}.short.log")
        msg = if self.failed then "failed" else "succeeded" end
        call = "echo \"Creation of live CD #{msg}\" >> #{RAILS_ROOT}/log/"
        system (call+"livecd#{port}.log")
        system (call+"livecd#{port}.short.log")
        system "echo  >> #{RAILS_ROOT}/log/livecd#{port}.log"
        if self.failed then
          self.log = IO.popen("tail -n80 #{RAILS_ROOT}/log/livecd#{port}.log").read
        end
    rescue StandardError => err
        self.log = "ruby code for live CD/DVD creation crashed: "+err
        self.failed = true
    end
    system "dotlockfile -u #{RAILS_ROOT}/livecd#{port}_lock"
    # store size and inform user via email
    ActiveRecord::Base.connection.reconnect! # needed after a possibly long time
    if !self.failed then
      self.generated = true
      self.size = 0
      if self.iso
        self.size += File.size(self.iso_image)
      end
      if self.kvm
        self.size += File.size(self.kvm_image)
      end
      if self.usb
        self.size += File.size(self.iso_image)
      end
      self.users.each do |user|
        MyMailer.deliver_livecd(user,"#{Livecd.rails_url}/livecds/#{self.id}")
      end
    else
      if self.first_try then
        self.users.each do |user|
          MyMailer.deliver_livecd_failed(user,self.fullname)
        end
        self.first_try = false
      end
    end
    self.generating = false
    self.save
  end

  # remaster the next non-generated liveCD (called from rake daemon)
  def self.remaster_next(ports,admin_ports)
    cd = Livecd.find_by_generated_and_generating_and_failed(false,false,false)
    # no current liveCD generation? 
    if cd.nil? and Dir.glob("livecd22*lock").empty?
      # ... then re-generate old ones
      cd = Livecd.find(:first,:conditions=>{:failed=>true},:order => "updated_at ASC")
      if !cd.nil? then
        cd.generate_sources
        cd.failed = false
        cd.log = nil
      end
    end
    if !cd.nil? then
      # get next port (use special ports for admins)
      if !cd.users[0].nil? and cd.users[0].has_role?('administrator')
        port = admin_ports[0]
        admin_ports.delete(port)
        admin_ports.push(port)
      else
        port = ports[0]
        ports.delete(port)
        ports.push(port)
      end
      # generate CD
      cd.generating = true
      cd.save
      cd.fork_remaster(port)
    end
  end

  # re-generate srcdeb (needed in case that srcdeb is wrong for some reasons)
  def generate_sources
    bundle = self.metapackage
    user = self.users[0]
    if !user.nil?
      if !bundle.nil?
        user.distribution_id = self.distribution.id
        user.derivative_id = self.derivative.id
        user.architecture_id = self.architecture.id
        user.license = self.license_type
        user.security = self.security_type
        self.srcdeb = RAILS_ROOT+"/"+user.install_bundle_sources(bundle)
      else
        if File.exists?(self.srcdeb)
          system "rm #{self.srcdeb}"
        end
        # get list of metapackages from installdeb
        depnames = Deb.deb_get_dependencies(self.installdeb)
        deps = depnames.map{|n| Metapackage.all.select{|m| m.debian_name==n}.first}.compact
        name = BasePackage.debianize_name("communtu-add-sources-"+user.login)
        version = user.profile_version.to_s
        description = I18n.t(:controller_suggestion_2)+user.login
        srcfile = Deb.makedeb_for_source_install(name,
                 version,
                 description,
                 deps,
                 self.distribution,
                 self.derivative,
                 self.license_type,
                 self.security_type,
                 self.architecture)
        self.srcdeb = RAILS_ROOT+"/"+srcfile
      end
      user.profile_changed = true
      self.save
    end
  end
  
  # register a livecd for a user
  def register(user)
    if !self.users.include? user
      LivecdUser.create({:livecd_id => self.id, :user_id => user.id})
    end
  end

  # deregister a livecd for a user; destroy cd if it has no more users
  def deregister(user)
    LivecdUser.find_all_by_livecd_id_and_user_id(self.id,user.id).each do |lu|
      lu.destroy
    end
    # are there any other users of this live CD?
    if self.users(force_reload=true).empty?
      # if not, destroy live CD
      self.destroy
    end
  end

  MSGS = ["Failed to fetch","could not set up","Cannot install","is not installable","not going to be installed", "Depends:","Error","error","annot","Wrong","not found","Connection closed", "E:"]
  
  def short_log
    if log.nil?
      return ""
    end
    lines = log.split("\n")
    MSGS.each do |msg|
      lines.reverse.each do |line|
        if !line.index(msg).nil?
          return line
        end
      end
    end
    return ""
  end

  def generate_hda
    tmpfile = IO.popen("mktemp").read.chomp
    self.vm_hda = SETTINGS['iso_path']+tmpfile
    self.save
    system "qemu-img create #{self.vm_hda} 5G"
  end

  def start_vm
    if self.vm_pid.nil?
      self.vm_pid = fork do
        ActiveRecord::Base.connection.reconnect!
        self.generate_hda
        exec "kvm -hda #{self.vm_hda} -cdrom #{self.iso_image} -m 1000 -vnc :1"
      end
      ActiveRecord::Base.connection.reconnect!
      self.save
    end
  end

  def stop_vm
    system "kill #{self.vm_pid}"
    sleep 1
    system "kill -9 #{self.vm_pid}"
    system "rm #{self.vm_hda}"
    self.vm_pid = nil
    self.vm_hda = nil
    self.save
  end

  def start_vm_basis
    if self.vm_pid.nil?
      self.vm_pid = fork do
        ActiveRecord::Base.connection.reconnect!
        exec "kvm -daemonize -drive file=/home/communtu/livecd/kvm/#{self.smallversion}.img,if=virtio,boot=on,snapshot=on -smp 4 -m 800 -nographic -redir tcp:2221::22"
      end
      fork do
        ActiveRecord::Base.connection.reconnect!
        system "scp -P 2221 -o StrictHostKeyChecking=no -o ConnectTimeout=500 #{self.srcdeb} root@localhost:/root/#{self.smallversion}/edit/root/"
        if !self.installdeb.index(".deb").nil? # install deb is a deb file? then copy it, too
          system "scp -P 2221 -o StrictHostKeyChecking=no -o ConnectTimeout=500 #{self.installdeb} root@localhost:/root/#{self.smallversion}/edit/root/"
        end
      end
      ActiveRecord::Base.connection.reconnect!
      self.save
    end
  end
  
  protected

  # cleanup of processes and iso files
  def delete_images
    if self.iso
      File.delete self.iso_image
    end
    if self.kvm
      File.delete self.kvm_image
    end
    if self.usb
      File.delete self.usb_image
    end
  end

  def before_destroy
    begin
      # if process for creating the livecd is waiting but has not started yet, kill it
      if !self.generated and !self.generating and !self.pid.nil?
        Process.kill("TERM", self.pid)
        # use time for deletion of iso as waiting time
        self.delete_images
        Process.kill("KILL", self.pid)
      else
        # only delete the iso
        self.delete_images
      end
    rescue
    end
  end
end
