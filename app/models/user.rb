require 'digest/sha1'
class User < ActiveRecord::Base
  # Virtual attribute for the unencrypted password
  attr_accessor :password  

  EmailAddress = begin
  qtext = '[^\\x0d\\x22\\x5c\\x80-\\xff]'
  dtext = '[^\\x0d\\x5b-\\x5d\\x80-\\xff]'
  atom = '[^\\x00-\\x20\\x22\\x28\\x29\\x2c\\x2e\\x3a-' +
    '\\x3c\\x3e\\x40\\x5b-\\x5d\\x7f-\\xff]+'
  quoted_pair = '\\x5c[\\x00-\\x7f]'
  domain_literal = "\\x5b(?:#{dtext}|#{quoted_pair})*\\x5d"
  quoted_string = "\\x22(?:#{qtext}|#{quoted_pair})*\\x22"
  domain_ref = atom
  sub_domain = "(?:#{domain_ref}|#{domain_literal})"
  word = "(?:#{atom}|#{quoted_string})"
  domain = "#{sub_domain}(?:\\x2e#{sub_domain})*"
  local_part = "#{word}(?:\\x2e#{word})*"
  addr_spec = "#{local_part}\\x40#{domain}"
  pattern = /\A#{addr_spec}\z/
end  

  validates_presence_of     :login, :email
  validates_presence_of     :password,                   :if => :password_required?
  validates_presence_of     :password_confirmation,      :if => :password_required?
  validates_length_of       :password, :within => 4..40, :if => :password_required?
  validates_confirmation_of :password,                   :if => :password_required?
#  validates_length_of       :firstname,    :within => 2..40
#  validates_length_of       :surname,    :within => 2..40
  validates_length_of       :login,    :within => 3..40
  validates_length_of       :email,    :within => 6..100
  validates_uniqueness_of   :login, :email, :case_sensitive => false
  validates_format_of       :email, :with => EmailAddress, :message => I18n.t(:not_accepted)
 
 #Messager dependencies
  has_many :sent_messages, :class_name => "Message", :foreign_key => "author_id", :dependent => :destroy
  has_many :received_messages, :class_name => "MessageCopy", :foreign_key => "recipient_id", :dependent => :destroy
  has_many :folders
 #Messager dependencies END
 
  has_many :permissions
  has_many :roles, :through => :permissions
  has_many :user_profiles, :dependent => :destroy
  belongs_to :distribution
  belongs_to :derivative
  belongs_to :language
  belongs_to :architecture
  has_many :user_packages 
  has_many :selected_packages, :through => :user_packages, :source => :base_package, \
      :conditions => "user_packages.is_selected = '1'"    
  has_many :deselected_packages, :through => :user_packages, :source => :base_package, \
      :conditions => "user_packages.is_selected = '0'"    
#  has_many :selected_metapackages, :through => :user_packages, :source => :base_package, \
#      :conditions => 'user_packages.base_package.class == Metapackage AND user_packages.is_selected'    
#  has_many :unselected_metapackages, :through => :user_packages, :source => :package_id, \
#      :conditions => 'user_packages.base_package.class == Metapackage && not user_packages.is_selected'    

  before_save :encrypt_password
  before_create :make_activation_code, :build_inbox
  
  def self.template_users
    template_role = Role.find(:first, :conditions => ["rolename = ?",'template'])
    ps = Permission.find(:all,:conditions => ["role_id = ?",template_role.id])
    ps.map {|p| p.user}
  end
  
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :login, :email, :password, :password_confirmation, :surname, :firstname
 
  class ActivationCodeNotFound < StandardError; end
  class AlreadyActivated < StandardError
    attr_reader :user, :message;
    def initialize(user, message=nil)
      @message, @user = message, user
    end
  end
  
  # Finds the user with the corresponding activation code, activates their account and returns the user.
  #
  # Raises:
  #  +User::ActivationCodeNotFound+ if there is no user with the corresponding activation code
  #  +User::AlreadyActivated+ if the user with the corresponding activation code has already activated their account
  def self.find_and_activate!(activation_code)
    raise ArgumentError if activation_code.nil?
    user = find_by_activation_code(activation_code)
    raise ActivationCodeNotFound if !user
    raise AlreadyActivated.new(user) if user.active?
    user.send(:activate!)
    user
  end
 
  def active?
    # the existence of an activation code means they have not activated yet
    activation_code.nil?
  end
 
  # Returns true if the user has just been activated.
  def pending?
    @activated
  end
 
  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  # Updated 2/20/08
  def self.authenticate(login, password)    
    u = find :first, :conditions => ['login = ?', login] # need to get the salt
    u && u.authenticated?(password) ? u : nil  
  end
 
  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end
 
  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end
 
  def authenticated?(password)
    crypted_password == encrypt(password)
  end
 
  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at
  end
 
  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    remember_me_for 2.weeks
  end
 
  def remember_me_for(time)
    remember_me_until time.from_now.utc
  end
 
  def remember_me_until(time)
    self.remember_token_expires_at = time
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save(false)
  end
 
  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(false)
  end
  
  def forgot_password
    @forgotten_password = true
    self.make_password_reset_code
  end
 
  def reset_password
    # First update the password_reset_code before setting the
    # reset_password flag to avoid duplicate email notifications.
    update_attribute(:password_reset_code, nil)
    @reset_password = true
  end  
 
  #used in user_observer
  def recently_forgot_password?
    @forgotten_password
  end
 
  def recently_reset_password?
    @reset_password
  end
  
  def self.find_for_forget(email)
    find :first, :conditions => ['email = ? and activation_code IS NULL', email]
  end
  
  def has_role?(rolename)
    self.roles.find_by_rolename(rolename) ? true : false
  end

  # update meta package selection to default given by sel
  def update_meta(m,sel)
    uid = self.id
    upk = UserPackage.find(:first, :conditions => ["user_id = ? and package_id = ?",uid,m.id])
    if upk.nil? then
      UserPackage.create(:user_id => uid,:package_id => m.id, :is_selected => sel)
    else
      upk.is_selected = sel
      upk.save
    end  
  end

  # update the rating for a category and all its children
  def update_rating(cat,val,lic,sec,anonymous_info,force_new)

    is_new = force_new
    cid    = cat.id

    if !anonymous_info[:anonymous] then

      uid = self.id
      up  = UserProfile.find(:first, :conditions => ["user_id = ? and category_id = ?",uid,cid])

      if up.nil? then 
        up = UserProfile.create(:user_id => uid, :category_id => cid, :rating => val)
        # no profile yet - we are in a new situation
        is_new = true  
      else
        # if rating has changed, it is new...
        if up.rating != val then is_new = true end
        up.rating = val
        up.save
      end
    else
      # anonymous user? then the rating is always new
      is_new = true
      anonymous_info[:session][:profile].store(cid, val)
    end

    if is_new then
      # if rating is new, then re-compute metapackage selection
      cat.metapackages.each do |m|
        if !anonymous_info[:anonymous] then
          update_meta(m,m.default_install && up.rating>0 && (m.is_published? or m.user_id == self.id))
        end
      end
      # also recursively update all the children
      cat.children.each do |child|
        update_rating(child,val,lic,sec,anonymous_info,force_new)
      end 
    end
  end
  
  # update meta package selection to default given by sel
  def update_meta(m,sel)
    uid = self.id
    upk = UserPackage.find(:first, :conditions => ["user_id = ? and package_id = ?",uid,m.id])
    if upk.nil? then
      UserPackage.create(:user_id => uid,:package_id => m.id, :is_selected => sel)
    else
      upk.is_selected = sel
      upk.save
    end  
  end
  
  def init_ratings
    self.first_login = 0
    self.save!
    #replace old list of packages...
    self.user_packages.each do |up|
      up.destroy
    end
    Category.find(1).children.each do |cat|
      up = UserProfile.find(:first,:conditions => {:user_id => self.id, :category_id => cat.id})
      val = if up.nil? then 0 else up.rating end
      update_rating(cat,val,self.license,self.security,{:anonymous => false},true)
    end  
  end

  # increase profile version number 
  def increase_version
    if self.profile_version.nil? then
       self.profile_version = 1
       self.profile_changed = true
    else
      if self.profile_changed then
        self.profile_version += 1
      end  
    end
  end
  
  #Messanger methods
  def inbox
    folders.find_by_name("Inbox")
  end

  def build_inbox
    if !self.anonymous?
      folders.build(:name => "Inbox")
    end
  end
  #Messanger methods END


  def install_sources
    if self.selected_packages.empty? then
      return nil
    end

    Dir.chdir RAILS_ROOT

    self.increase_version

    name = BasePackage.debianize_name("communtu-add-sources-"+self.login)
    version = self.profile_version.to_s

    debfile = Dir.glob("debs/#{name}/#{name}_#{version}*deb")[0]
    # if profile has changed, generate new debian metapackage
    if self.profile_changed or debfile.nil? then
      description = I18n.t(:controller_suggestion_2)+self.login
      debfile = Deb.makedeb_for_source_install(name,
                 version,
                 description,
                 self.selected_packages,
                 self.distribution,
                 self.derivative,
                 self.license,
                 self.security)
      self.profile_changed = false
    end
    self.save
    return debfile
  end

  def install_bundle_sources(bundle)
    Dir.chdir RAILS_ROOT

    name = BasePackage.debianize_name("communtu-add-sources-#{self.login}-#{bundle.name}")
    version = self.profile_version.to_s

    description = I18n.t(:controller_suggestion_4)+bundle.name
    debfile = Deb.makedeb_for_source_install(name,
                 version,
                 description,
                 [bundle],
                 self.distribution,
                 self.derivative,
                 self.license,
                 self.security)
    return debfile
  end

  def install_package_sources(package)
    Dir.chdir RAILS_ROOT
    repos = package.repositories_dist(self.distribution,self.architecture)
    name = BasePackage.debianize_name("communtu-add-sources-#{self.login}-#{package.name}")
    version = "0.1"
    description = I18n.t(:controller_suggestion_6)+package.name
    # only install sources, no packages
    codename = Deb.compute_codename(self.distribution,
                 self.derivative,
                 self.license,
                 self.security)
    debfile = Deb.makedeb(name,version,[],description,codename,self.derivative,repos)
    return debfile
  end

  def install_bundle_as_meta
    if self.selected_packages.empty? then
      return nil
    end

    Dir.chdir RAILS_ROOT
    self.increase_version

    name = BasePackage.debianize_name("communtu-install-"+self.login)
    version = self.profile_version.to_s

    debfile = Dir.glob("debs/#{name}/#{name}_#{version}*deb")[0]
    # if profile has changed, generate new debian metapackage
    if self.profile_changed or debfile.nil? then
      description = I18n.t(:controller_suggestion_8)+self.login
      codename = Deb.compute_codename(self.distribution,
                 self.derivative,
                 self.license,
                 self.security)
      debfile = Deb.makedeb(name,
                 version,
                 self.selected_packages.map{|p| p.debian_name},
                 description,
                 codename,
                 self.derivative,
                 [])
      self.profile_changed = false
    end
    self.save
    return debfile
  end

  def fullversion
    self.derivative.name.downcase+"-"+self.distribution.name.gsub(/[a-zA-Z ]/,'')+"-desktop-"+self.architecture.name
  end

  def livecd
    system "dotlockfile -r 1000 #{RAILS_ROOT}/livecd_lock"
    system "(echo; echo \"------------------------------------\"; echo \"Creating live CD\"; date) >> #{RAILS_ROOT}/log/livecd.log"
    ver = self.fullversion
    deb1 = RAILS_ROOT + "/" + self.install_sources
    deb2 = RAILS_ROOT + "/" + self.install_bundle_as_meta
    isobase = File.basename(deb2).gsub(/\.deb$/,'')
    iso = "#{RAILS_ROOT}/public/debs/#{isobase}.iso"
    baseurl = if RAILS_ROOT.index("test").nil? then "http://communtu.org" else "http://test.communtu.de" end
    isourl = "#{baseurl}/debs/#{isobase}.iso"
    if Dir.glob(iso)[0].nil? then
      res = system "sudo -u communtu #{RAILS_ROOT}/script/remaster create #{ver} #{iso} #{isobase} #{deb1} #{deb2} >> #{RAILS_ROOT}/log/livecd.log 2>&1"
    else
      res = true
    end
    if !res then
      system "(echo; echo \"Creation of livd CD failed\"; echo) >> #{RAILS_ROOT}/log/livecd.log"
    end
    system "(echo; echo \"finished at:\"; date; echo; echo) >> #{RAILS_ROOT}/log/livecd.log"
    system "dotlockfile -u #{RAILS_ROOT}/livecd_lock"
    if res then
      MyMailer.deliver_livecd(self,isourl)
    else
      MyMailer.deliver_livecd_failed(self)
    end
  end

  def test_livecd
    ver = self.fullversion
    deb1 = RAILS_ROOT + "/" + self.install_sources
    deb2 = RAILS_ROOT + "/" + self.install_bundle_as_meta
    isobase = File.basename(deb2).gsub(/\.deb$/,'')
    iso = "#{RAILS_ROOT}/public/debs/#{isobase}.iso"
    isourl = "http://communtu.org/debs/#{isobase}.iso"
    if Dir.glob(iso)[0].nil? then
      system "echo "
      system "echo \"##{ver} #{iso} #{isobase} #{deb1} #{deb2}\" >> #{RAILS_ROOT}/log/livecd.log"
      system "echo hallo > #{iso}"
    end
    MyMailer.deliver_livecd(self,isourl)
  end


  protected
  
  # before filter
  def encrypt_password
    return if password.blank?
    self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
    self.crypted_password = encrypt(password)
  end
      
  def password_required?
    crypted_password.blank? || !password.blank?
  end
    
  def make_activation_code
    self.activation_code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
  end
 
  def make_password_reset_code
    self.password_reset_code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
  end

  private
  
  def activate!
    @activated = true
    self.update_attribute(:activated_at, Time.now.utc)
  self.update_attribute(:activation_code, nil)
  end    
   
end
