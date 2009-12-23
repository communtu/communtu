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

  def filename
    "#{RAILS_ROOT}/public/debs/#{self.name}-#{self.fullversion}.iso"
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
  
  def remaster(srcdeb,installdeb)
    system "dotlockfile -r 1000 #{RAILS_ROOT}/livecd_lock"
    system "(echo; echo \"------------------------------------\"; echo \"Creating live CD\"; date) >> #{RAILS_ROOT}/log/livecd.log"
    ver = self.fullversion
    iso = self.filename
    isobase = File.basename(iso)
    baseurl = if RAILS_ROOT.index("test").nil? then "http://communtu.org" else "http://test.communtu.de" end
    isourl = "#{baseurl}/debs/#{isobase}"
    if Dir.glob(iso)[0].nil? then
      res = system "sudo -u communtu #{RAILS_ROOT}/script/remaster create #{ver} #{iso} #{isobase} #{srcdeb} #{installdeb} >> #{RAILS_ROOT}/log/livecd.log 2>&1"
    else
      res = true
    end
    if !res then
      system "(echo; echo \"Creation of livd CD failed\"; echo) >> #{RAILS_ROOT}/log/livecd.log"
    end
    system "(echo; echo \"finished at:\"; date; echo; echo) >> #{RAILS_ROOT}/log/livecd.log"
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

end
