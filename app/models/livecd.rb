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

# each liveCD is stored in the database as an object of class Livecd
# this allows for better error logging and recovery
# note that the iso itself is stored in the file system, however

# a liveCD can be based either on a user profile or on a bundle

# database fields: 
# architecture_id: architecture of the liveCD
# derivative_id: derivative of the liveCD
# distribution_id: distribution of the liveCD
# downloaded: number of downloads
# failed: has build process failed?
# first_try: is this the first try to build the liveCD? (only then a failure message is sent)
# generated: has the liveCD been successfully built?
# generating: currently, the liveCD is being built
# installdeb: deb for the bundle installing the contents of the liveCD
# iso: location of iso image file on the server
# kvm: does the user want to have a kvm image?
# license_type: 0 = free, 1 = free or proprietary.
# log: relevant extract of log file
# metapackage_id: bundle on which the liveCD is based
# name
# pid: process id of forked process that builds the liveCD
# profile_version: version of user profile that has been used for liveCD build
# security_type: 0 = Ubuntu only, 1 = also Ubuntu community, 2 = also third-party.
# size: size of the iso image
# srcdeb: deb file for installing the sources
# usb: does the user want to have a usb image? (deprecated)
# vm_hda: hard disk file for virtual machine (when testing liveCD via vnc)
# vm_pid: process id of virtual machine (when testing liveCD via vnc)

SSH_OPTIONS = "-q -o StrictHostKeyChecking=no -o ConnectTimeout=500"

require "lib/utils.rb"
if SETTINGS["livecd"] then require 'libvirt' end

class Livecd < ActiveRecord::Base
  belongs_to :distribution
  belongs_to :derivative
  belongs_to :architecture
  belongs_to :metapackage
  has_many :livecd_users, :dependent => :destroy
  has_many :users, :through => :livecd_users
  has_many :translations, :through => :metapackage
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
    if name.nil? or name.empty?
      return I18n.t(:livecd_no_name)
    end
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
  
  # mark a cd for remastering
  def mark_remaster
    self.failed = false
    self.generating = false
    self.generated = false
    self.log = nil
    self.save
    # remastering is now done by daemon
  end

  # create the liveCD in a forked process
  def fork_remaster(port=2222)
      nice = (self.users[0].nil? or !self.users[0].has_role?('administrator'))
      nicestr = if nice then "nice -n +10 " else "" end
      self.pid = fork do
            ActiveRecord::Base.connection.reconnect!
	 	        system "echo \"Livecd.find(#{self.id.to_s}).remaster(#{port.to_s})\" | #{nicestr} nohup script/console production"
      end
      Process.detach(self.pid) # avoid zombie child
      ActiveRecord::Base.connection.reconnect!
      self.save
  end

  # created liveCD, using script/remaster
  def remaster(port=2222)
    ActiveRecord::Base.connection.reconnect!
    self.port = port
    self.save
    begin
        # use lock in order to prevent parallel generation of multiple isos with same port
        while not (system "dotlockfile -p -r 1000 #{RAILS_ROOT}/livecd#{port}_lock") do end
        self.generating = true
        self.log = ""
        self.save
        write_log "\n------------------------------------"
        log_start = "#{date_now} - #{port}: Creating live CD ##{self.id} #{self.fullname}"
        write_log log_start
        write_log log_start, true
        # check if there is enough disk space (at least 25 GB)
        while disk_free_space(SETTINGS['iso_path']) < 25000000000
          # destroy the oldest liveCD
          cd=Livecd.find(:first,:order=>"updated_at ASC")
          msg = "#{date_now} - #{port}: Disk full - deleting live CD #{cd.id}"
          write_log msg
          write_log msg, true
          cd.destroy
        end
        # remaster the CD
        err = self.remaster_it
        self.failed = !err.empty?
        write_log err
        write_log ""
    rescue StandardError => err
        write_log err.to_s
        self.failed = true
    rescue NoMethodError => err
        write_log err.to_s
        self.failed = true
    end
    msg = if self.failed then "failed" else "succeeded" end
    msg = "#{date_now} - #{port}: Creation of live CD ##{self.id} #{msg}"
    write_log msg
    write_log msg, true
    write_log "", false, true # flush logfile
    if self.failed then
      self.log += `grep -A 1000000 \"#{log_start}\" #{RAILS_ROOT}/log/livecd#{port}.log`
    end
    # kill VM, necessary in case of abrupt exit
    system "sudo kill-kvm #{port}"
    # release lock
    system "dotlockfile -u #{RAILS_ROOT}/livecd#{port}_lock"
    # store size and inform user via email
    ActiveRecord::Base.connection.reconnect! # needed after a possibly long time
    if !self.failed then
      self.generated = true
      self.size = File.size(self.iso_image)
      self.livecd_users.each do |lu|
        MyMailer.deliver_livecd(lu.user,"#{Livecd.rails_url}/livecds/#{self.id}",lu.locale)
      end
    else
      # mysql problem? then retry
      if !self.log.nil? and self.log.include?("Mysql::Error: MySQL server has gone away") then
        self.mark_remaster
      # first try? then inform users about failure  
      elsif self.first_try then
        self.livecd_users.each do |lu|
          MyMailer.deliver_livecd_failed(lu)
        end
        self.first_try = false
      end
    end
    self.generating = false
    self.save
    self.init_short_log
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

  def remaster_it
    Dir.chdir SETTINGS["livecd_folder"] do
      write_log "*** checking liveCD parameters"
      if !File.exists?(self.srcdeb) 
        return "#{self.srcdeb} not found"     
      end
      if (isdeb = !installdeb.scan(/.deb$/).empty?) then
        if !File.exists?(self.installdeb) 
          return "#{self.installdeb} not found"     
        end
      end      
      if !File.exists?("kvm/#{self.smallversion}.img") then
        return "kvm/#{self.smallversion}.img not found"
      end

      # normal users get nice'd
      nice = (self.users[0].nil? or !self.users[0].has_role?('administrator'))
      nicestr = if nice then "nice -n +19 " else "" end
      write_log "*** starting virtual machine"
      system_with_log "#{nicestr}kvm -daemonize -drive file=kvm/#{self.smallversion}.img,if=virtio,boot=on,snapshot=on -smp 4 -m 600 -net nic,model=virtio -net user -nographic -redir tcp:#{port}::22"
      safe_system "stty echo" # turn echo on again (kvm somehow turns it off)

      write_log "*** waiting for start of virtual machine, setting nameserver"
      ssh "echo \\\"nameserver #{SETTINGS['nameserver']}\\\" > /root/#{self.smallversion}/edit/etc/resolv.conf"

      write_log "*** adding new sources and keys, using #{self.srcdeb}"
      scp "#{self.srcdeb} root@localhost:/root/#{self.smallversion}/edit/"
      source = `basename #{self.srcdeb}`.chomp
      chroot "dpkg -i #{source}"
      ssh "rm /root/#{self.smallversion}/edit/#{source}"
      sleep 15

      write_log "*** setting debconf options"
      chroot "sed -i 's/Templates: templatedb/Templates: templatedb\\nFrontend: readline\\nPriority: critical/' /etc/debconf.conf"
      #write_log "*** configuring sources.list for apt-proxy"
      #ssh "cp /root/#{self.smallversion}/edit/etc/apt/sources.list . ; chroot /root/#{self.smallversion}/edit sed -i 's/http:\/\//http:\/\/$APT_PROXY:3142\//' /etc/apt/sources.list; chroot /root/#{self.smallversion}/edit apt-get update"

      write_log "*** system mounts"
      chroot "mount -t proc none /proc"
      chroot "mount -t sysfs none /sys"
      chroot "mount -t devpts devpts /dev/pts"

      bundles = if isdeb then 
                  self.bundles.map(&:debian_name).join(" ") 
                else self.installdeb 
                end 
      write_log "*** installing packages #{bundles}"
      # get all packages that are to be installed
      packages = Deb.get_install_packages(chroot "apt-get install -s #{bundles}", true)
      # sort packages by priority
      packages_prios = {}
      packages.each do |pname|
        prio = Package.prio(pname)
        if packages_prios[prio].nil? then
          packages_prios[prio] = [pname]
        else  
          packages_prios[prio] << [pname]
        end          
      end
      # install packages with ascending priority
      packages_prios.keys.sort.each do |prio|
        ps = packages_prios[prio]
        chroot "apt-get install -y --force-yes #{ps.join(" ")}"
      end
      
      write_log "*** reverting special settings"
      #ssh "cp sources.list /root/#{self.smallversion}/edit/etc/apt/"
      ssh "export LANG=C; chroot /root/#{self.smallversion}/edit sed -i -r 's/Frontend: readline|Priority: critical//' /etc/debconf.conf; chroot /root/#{self.smallversion}/edit sh -c \\\"export LANG=C; apt-get update\\\"; rm /root/#{self.smallversion}/edit/etc/resolv.conf"
    
      write_log "creating iso image"
      scp "#{RAILS_ROOT}/script/remaster_ubuntu.sh root@localhost:"
      ssh "/root/remaster_ubuntu.sh regen /root/#{self.smallversion} #{self.name} /root/new.iso"
      ssh "cd /root/#{self.smallversion}/extract-cd; \
             mkisofs -r -V #{self.name[0,25]} -cache-inodes -J -l \
           -b isolinux/isolinux.bin -c isolinux/boot.cat \
           -no-emul-boot -boot-load-size 4 -boot-info-table \
           -allow-limited-size -udf -o - .", self.iso_image
      ssh "halt"
    end
    return ""
  end

  def system_with_log(str)
    write_log("+"+str)
    safe_system("#{str} >> #{RAILS_ROOT}/log/livecd#{self.port}.log 2>&1")
  end  
  
  def write_log(str,noport=false,flush=false)
    portstr = if noport then "" else self.port.to_s end
    File.open("#{RAILS_ROOT}/log/livecd#{portstr}.log","a") do |f|
      f.puts str
      if flush then f.flush end
    end
  end 

  def ssh(str, redirect="")
    if redirect.empty?
      system_with_log("ssh -p #{self.port} #{SSH_OPTIONS} root@localhost \"#{str}\"")
    else
      write_log("+"+str)
      safe_system("ssh -p #{self.port} #{SSH_OPTIONS} root@localhost \"#{str}\" > #{redirect} 2> #{RAILS_ROOT}/log/livecd#{self.port}.log")
    end
  end  

  def scp(str)
    system_with_log("scp #{SSH_OPTIONS} -P #{self.port} #{str}")
  end  

  def chroot(str,return_log=false)
    if return_log then
      `ssh -p #{self.port} #{SSH_OPTIONS} root@localhost \"chroot /root/#{self.smallversion}/edit #{str}\"`
    else
      ssh "chroot /root/#{self.smallversion}/edit #{str}"
    end  
  end
  # get list of metapackages, either from database or from installdeb
  def bundles
    begin
      if self.metapackage.nil? 
        depnames = Deb.deb_get_dependencies(self.installdeb)
        depnames.map{|n| Metapackage.all.select{|m| m.debian_name==n}.first}.compact
      else
        [self.metapackage]
      end
    rescue
      []
    end  
  end
  
  # check whether all involved bundles have been published
  def bundles_published?
    if self.metapackage.nil? 
      u = self.users[0]
      if u.nil?
        return false
      end
      u.selected_packages.map(&:is_published?).all?
    else
      self.metapackage.is_published?
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
        deps = self.bundles
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
      LivecdUser.create({:livecd_id => self.id, :user_id => user.id, :locale => I18n.locale.to_s})
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
  
  def init_short_log
    self.short_log = self.compute_short_log.gsub(/^[ \t]*/,"")
    self.save
  end
  
  def compute_short_log
    if log.nil?
      return ""
    end
    lines = log.split("\n")
    MSGS.each do |msg|
      packages = []
      lines.reverse.each do |line|
        if line[0]==32 then
          packages << line.chomp
        end
        if !line.index(msg).nil?
          line.chomp!
          if line == "Errors were encountered while processing:"
            line += packages.join(",")
          end
          return line
        end
      end
    end
    return ""
  end

  def self.vnc(dom)
    s = dom.xml_desc.scan(/graphics.*port='[0-9]+/)[0]
    if s.nil? then
      return I18n.t(:vm_no_vnc)
    end
    s.scan(/[0-9]+/)[0]
  end
  
  def vm_name(user)
    "cd_#{self.id}_#{self.name}_user_#{user.login}"
  end
  
  def start_vm(user)
    # only proceed if the iso image is present, as basis of the VM
    if !File.exists?(self.iso_image)
      return I18n.t(:vm_no_iso_found)
    end

    # check for cpu load and available memory 
    cpu_idle = `top -b -n 1 |grep Cpu`.scan(/[0-9.]*%id/)[0].to_i
    free = `free -k`.scan(/buffers.cache:[ 0-9]*/)[0].split(" ")[-1].to_i
    mem = SETTINGS['vm_mem_size']
    if cpu_idle<20 or free<2*mem
      return I18n.t(:vm_too_much_cpu_load)
    end
    # todo: generalise to other servers; check for free space using conn.node_free_memory

    # has the vm already been created?
    conn = Libvirt::open("qemu:///system") # TODO: generalise to other servers
    name = vm_name(user)
    dom = begin
      conn.lookup_domain_by_name(name)
    rescue
      nil
    end  
    if !dom.nil?
      conn.close
      return Livecd.vnc(dom)
    end
    
    # create the guest disk
    disk = SETTINGS['vm_path']+"/"+name+".qcow2"
    vm_hd_size = SETTINGS['vm_hd_size']
    # keep old user data
    if !File.exists?(disk)
      if !(system "qemu-img create -f qcow2 #{disk} #{vm_hd_size}")
        return I18n.t(:vm_no_space)
        conn.close
      end  
    end    
    #system "chmod +w #{disk}"

    # translate architecture to libvirt format
    arch = case self.architecture.name
        when "i386" then "i686"
        when "amd64" then "x86_64"
      end
    
    # the XML that describes the virtual machine
    new_dom_xml = <<EOF
    <domain type='kvm'>
      <name>#{name}</name>
      <memory>#{mem}</memory>
      <currentMemory>#{mem}</currentMemory>
      <vcpu>1</vcpu>
      <os>
        <type arch='#{arch}'>hvm</type>
        <boot dev='hd'/>
        <boot dev='cdrom'/>
      </os>
      <features>
        <acpi/>
        <apic/>
        <pae/>
      </features>
      <clock offset='utc'/>
      <on_poweroff>destroy</on_poweroff>
      <on_reboot>restart</on_reboot>
      <on_crash>restart</on_crash>
      <devices>
        <disk type='file' device='disk'>
          <driver name='qemu' type='qcow2'/>
          <source file='#{disk}'/>
          <target dev='vda' bus='virtio'/>
        </disk>
        <disk type='file' device='cdrom'>
          <driver name='qemu' type='raw'/>
          <source file='#{self.iso_image}'/>
          <target dev='hdc' bus='ide'/>
          <readonly/>
        </disk>
        <interface type='network'>
          <source network='default'/>
          <target dev='vnet0'/>
          <model type='virtio'/>
        </interface>
        <serial type='pty'>
          <target port='0'/>
        </serial>
        <console type='pty'>
          <target port='0'/>
        </console>
        <input type='mouse' bus='ps2'/>
        <graphics type='vnc' port='-1' autoport='yes' listen='0.0.0.0' keymap='#{I18n.locale}'/>
        <video>
          <model type='cirrus' vram='9216' heads='1'/>
        </video>
      </devices>
    </domain>
EOF

    # define and start domain (vm) 
    begin
      dom = conn.define_domain_xml(new_dom_xml)
      dom.create
    rescue StandardError => err
      conn.close
      log = `sudo libvirt-log #{name}`
      return "VM error: #{err.to_s} <br>#{log}"
    end  
    conn.close
    return Livecd.vnc(dom)
  end

  def stop_vm(user)
    conn = Libvirt::open("qemu:///system") # TODO: generalise to other servers
    name = vm_name(user)
    dom = begin
      conn.lookup_domain_by_name(name)
    rescue
      nil
    end  
    if !dom.nil?
      begin
        dom.destroy # stop domain
        dom.undefine # delete domain  
      rescue    
      end
    end  
    conn.close
  end

  def start_vm_basis
    if self.vm_pid.nil?
      self.vm_pid = fork do
        ActiveRecord::Base.connection.reconnect!
        system "kvm -daemonize -drive file=/home/communtu/livecd/kvm/#{self.smallversion}.img,if=virtio,boot=on,snapshot=on -smp 4 -m 800 -nographic -redir tcp:2221::22"
        cmd = "scp -P 2221 -o StrictHostKeyChecking=no -o ConnectTimeout=500 #{self.srcdeb} root@localhost:/root/#{self.smallversion}/edit/root/"
        system "echo #{cmd} >> log/vm.log"
        system "#{cmd} >> log/vm.log"
        if !self.installdeb.index(".deb").nil? # install deb is a deb file? then copy it, too
          cmd = "scp -P 2221 -o StrictHostKeyChecking=no -o ConnectTimeout=500 #{self.installdeb} root@localhost:/root/#{self.smallversion}/edit/root/"
          system "echo #{cmd} >> log/vm.log"
          system "#{cmd} >> log/vm.log"
        end
      end
      ActiveRecord::Base.connection.reconnect!
      self.save
    end
  end
  
  # use edos_checkdeb for detection of conflicts of a livecd
  def edos_conflicts
    name = "livecd-"+self.fullname
    bundle_names = [name]
    bundle_list = self.bundles.map(&:debian_name)
    package_lists = { bundle_list => [self.derivative]}
    self.conflict_msg = Metapackage.call_edos(name,bundle_names,package_lists,self.distribution,self.architecture) 
    self.save
    return self.conflict_msg
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
