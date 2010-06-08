# each liveCD is stored in the database as an object of class Livecd
# this allows for better error logging and recovery
# note that the iso itself is stored in the file system, however

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

  # base url of LiveCD on the communtu server
  def base_url
    baseurl = if RAILS_ROOT.index("test").nil? then "http://communtu.org" else "http://test.communtu.de" end
    return "#{baseurl}/isos/#{self.fullname}"
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
  def fork_remaster
      self.pid = fork do
	 	        system 'echo "Livecd.find('+self.id.to_s+').remaster" | nohup script/console production'
      end
      self.save
  end

  # created liveCD, using script/remaster
  def remaster
    ver = self.smallversion
    fullname = self.fullname
    # need to generate iso, use lock in order to prevent parallel generation of multiple isos
    begin
        safe_system "dotlockfile -p -r 1000 #{RAILS_ROOT}/livecd_lock"
        self.generating = true
        self.save
        # log to log/livecd.log
        system "(echo; echo \"------------------------------------\")  >> #{RAILS_ROOT}/log/livecd.log"
        call = "(echo \"Creating live CD #{fullname}\"; date) >> #{RAILS_ROOT}/log/"
        system (call+"livecd.log")
        system (call+"livecd.short.log")
        # check if there is enough disk space (at least 25 GB)
        while IO.popen("df | grep /local").read.split(" ")[3].to_i < 25000000
          # destroy the oldest liveCD
          cd=Livecd.find(:first,:order=>"created_at ASC")
          call = "(echo \"Disk full - deleting live CD #{cd.id}\" >> #{RAILS_ROOT}/log/"
          system (call+"livecd.log")
          system (call+"livecd.short.log")
          cd.destroy
        end
        # Jaunty and lower need virtualisation due to requirement of sqaushfs version >= 4 (on the server, we have Hardy)
        if self.distribution_id < 5 then
          virt = "-v "
        else
          virt = ""
        end
        isoflag = self.iso ? "-iso #{self.iso_image} " : ""
        kvmflag = self.kvm ? "-kvm #{self.kvm_image} " : ""
        usbflag = self.sub ? "-usb #{self.usb_image} " : ""
        remaster_call = "#{RAILS_ROOT}/script/remaster create #{virt}#{isoflag}#{kvmflag}#{usbflag}#{ver} #{self.name} #{self.srcdeb} #{self.installdeb} 2222 >> #{RAILS_ROOT}/log/livecd.log 2>&1"
        system "echo \"#{remaster_call}\" >> #{RAILS_ROOT}/log/livecd.log"
        self.failed = !(system remaster_call)
        # kill VM and release lock, necessary in case of abrupt exit
        system "sudo kill-kvm 2222"
        system "dotlockfile -u /home/communtu/livecd/livecd2222.lock"
        system "echo  >> #{RAILS_ROOT}/log/livecd.log"
        call = "echo \"finished at:\"; date >> #{RAILS_ROOT}/log/"
        system (call+"livecd.log")
        system (call+"livecd.short.log")
        msg = if self.failed then "failed" else "succeeded" end
        call = "echo \"Creation of live CD #{msg}\" >> #{RAILS_ROOT}/log/"
        system (call+"livecd.log")
        system (call+"livecd.short.log")
        system "echo  >> #{RAILS_ROOT}/log/livecd.log"
        if self.failed then
          self.log = IO.popen("tail -n80 #{RAILS_ROOT}/log/livecd.log").read
        end
    rescue
        self.log = "ruby code for live CD/DVD creation crashed"
        self.failed = true
    end
    system "dotlockfile -u #{RAILS_ROOT}/livecd_lock"
    # store size and inform user via email
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
        MyMailer.deliver_livecd(user,livecdpath(self))
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

  def self.remaster_next
    cd = Livecd.find_by_generated_and_generating_and_failed(false,false,false)
    if !cd.nil? then
      cd.generating = true
      cd.save
      cd.remaster
    end
  end

  def generate_sources
    bundle = self.metapackage
    user = self.users[0]
    if !user.nil? and !bundle.nil?
      user.distribution_id = self.distribution.id
      user.derivative_id = self.derivative.id
      user.architecture_id = self.architecture.id
      user.license = self.license_type
      user.security = self.security_type
      user.profile_changed = true
      self.srcdeb = RAILS_ROOT+"/"+user.install_bundle_sources(bundle)
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

  MSGS = ["Failed to fetch","could not set up","Cannot install","is not installable","not going to be installed", "Depends:","Error","error","annot","Wrong","not found","Connection closed"]
  
  def short_log
    if log.nil?
      return ""
    end
    lines = log.split("\n")
    lines.each do |line|
      MSGS.each do |msg|
        if !line.index(msg).nil?
          return line
        end
      end
    end
    return ""
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
