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

require "lib/utils.rb"
require 'libvirt'

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
        while not (system "dotlockfile -p -r 1000 #{RAILS_ROOT}/livecd#{port}_lock") do end
        self.generating = true
        self.save
        # log to log/livecd.log
        system "(echo; echo \"------------------------------------\")  >> #{RAILS_ROOT}/log/livecd#{port}.log"
        call = "echo \"#{date_now} - #{port}: Creating live CD ##{self.id} #{fullname}\" >> #{RAILS_ROOT}/log/"
        system (call+"livecd#{port}.log")
        system (call+"livecd.log")
        # check if there is enough disk space (at least 25 GB)
        while disk_free_space(SETTINGS['iso_path']) < 25000000000
          # destroy the oldest liveCD
          cd=Livecd.find(:first,:order=>"updated_at ASC")
          call = "(echo \"#{date_now} - #{port}: Disk full - deleting live CD #{cd.id}\" >> #{RAILS_ROOT}/log/"
          system (call+"livecd#{port}.log")
          system (call+"livecd.log")
          cd.destroy
        end
        # normal users get nice'd
        nice = (self.users[0].nil? or !self.users[0].has_role?('administrator'))
        nicestr = if nice then "-nice " else "" end
        # Jaunty and lower need virtualisation due to requirement of squashfs version >= 4 (on the server, we have Hardy)
        if self.distribution.name[0] <= 74 then # 74 is "J"
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
        msg = if self.failed then "failed" else "succeeded" end
        call = "echo \"#{date_now} - #{port}: Creation of live CD ##{self.id} #{msg}\" >> #{RAILS_ROOT}/log/"
        system (call+"livecd#{port}.log")
        system (call+"livecd.log")
        system "echo  >> #{RAILS_ROOT}/log/livecd#{port}.log"
        if self.failed then
          self.log = IO.popen("tail -n80 #{RAILS_ROOT}/log/livecd#{port}.log",&:read)
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

  def self.vnc(dom)
    s = dom.xml_desc.scan(/graphics.*port='[0-9]+/)[0]
    if s.nil? then
      return I18n.t(:vm_no_vnc)
    end
    s.scan(/[0-9]+/)[0]
  end
  
  def vm_name(user)
    "cd_#{self.id}_user_#{user.id}"
  end
  
  def start_vm(user)
    # only proceed if the iso image is present, as basis of the VM
    if !File.exists?(self.iso_image)
      return I18n.t(:vm_no_iso_found)
    end

    # check for cpu load and available memory 
    cpu_idle = IO.popen("top -b -n 1 |grep Cpu",&:read).scan(/[0-9.]*%id/)[0].to_i
    free = IO.popen("free -k",&:read).scan(/buffers.cache:[ 0-9]*/)[0].split(" ")[-1].to_i
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
    if !(system "rm -f qcow2 #{disk}; qemu-img create -f qcow2 #{disk} #{vm_hd_size}")
      return I18n.t(:vm_no_space)
      conn.close
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
        <graphics type='vnc' port='-1' autoport='yes' listen='0.0.0.0'/>
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
      log = IO.popen("sudo libvirt-log #{name}",&:read)
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
      dom.destroy # stop domain
      dom.undefine # delete domain  
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
