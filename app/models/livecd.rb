class Livecd < ActiveRecord::Base
  belongs_to :distribution
  belongs_to :derivative
  belongs_to :architecture
  belongs_to :user
  belongs_to :metapackage
  validates_presence_of :name, :distribution, :derivative, :architecture, :user

  def fullversion
    self.derivative.name.downcase+"-"+self.distribution.name.gsub(/[a-zA-Z ]/,'')+"-desktop-"+self.architecture.name
  end

  def fullname
    "#{self.name}-#{self.fullversion}"
  end

  def filename
    "#{RAILS_ROOT}/public/debs/#{self.fullname}.iso"
  end

  def url
    baseurl = if RAILS_ROOT.index("test").nil? then "http://communtu.org" else "http://test.communtu.de" end
    return "#{baseurl}/debs/#{self.fullname}.iso"
  end

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

  def fork_remaster
      self.pid = fork do
        system 'echo "Livecd.find('+self.id.to_s+').remaster" | nohup script/console production'
      end
      self.save
  end

  def remaster
    system "dotlockfile -r 1000 #{RAILS_ROOT}/livecd_lock"
    begin
      self.generating = true
      self.save
      system "(echo; echo \"------------------------------------\"; echo \"Creating live CD\"; date) >> #{RAILS_ROOT}/log/livecd.log"
      ver = self.fullversion
      iso = self.filename
      isourl = self.url
      fullname = self.fullname
      if Dir.glob(iso)[0].nil? then
        # Karmic and higher need virtualisation due to requirement of sqaushfs version >= 4
        if self.distribution_id >= 5 then
          virt = "-v "
        else
          virt = ""
        end
        remaster_call = "sudo -u communtu #{RAILS_ROOT}/script/remaster create #{virt}#{ver} #{iso} #{self.name} #{self.srcdeb} #{self.installdeb} >> #{RAILS_ROOT}/log/livecd.log 2>&1"
        system "echo \"#{remaster_call}\" >> #{RAILS_ROOT}/log/livecd.log"
        res = system remaster_call
        # kill VM, necessary in case of abrupt exit
        system "pkill -f \"kvm -daemonize .* -redir tcp:2222::22\""
      else
        res = true
      end
      system "(echo; echo \"finished at:\"; date; echo; echo) >> #{RAILS_ROOT}/log/livecd.log"
      if !res then
        system "(echo; echo \"Creation of livd CD failed\"; echo) >> #{RAILS_ROOT}/log/livecd.log"
        self.log = IO.popen("tail -n80 #{RAILS_ROOT}/log/livecd.log").read
      end
      self.failed = !res
      self.generating = false
      self.save
    rescue
      self.log = "ruby code for live CD/DVD creation crashed"
      self.save
      res = false
    end
    system "dotlockfile -u #{RAILS_ROOT}/livecd_lock"
    if res then
      self.generated = true
      self.size = File.size(self.filename)
      self.save
      MyMailer.deliver_livecd(self.user,isourl)
    else
      MyMailer.deliver_livecd_failed(self.user)
    end
  end

  protected

  def before_destroy
    begin
      # if process for creating the livecd is waiting but has not started yet, kill it
      if !self.generated and !self.generating and !self.pid.nil?
        Process.kill("TERM", self.pid)
        # use time for deletion of iso as waiting time
        File.delete self.filename
        Process.kill("KILL", self.pid)
      else
        # only delete the iso
        fork do File.delete self.filename end
      end
    rescue
    end
  end
end
