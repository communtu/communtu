require 'digest/sha1'
class User < ActiveRecord::Base
  # Virtual attribute for the unencrypted password
  attr_accessor :password  
 
  validates_presence_of     :login, :email
  validates_presence_of     :password,                   :if => :password_required?
  validates_presence_of     :password_confirmation,      :if => :password_required?
  validates_length_of       :password, :within => 4..40, :if => :password_required?
  validates_confirmation_of :password,                   :if => :password_required?
  validates_length_of       :login,    :within => 3..40
  validates_length_of       :email,    :within => 6..100
  validates_uniqueness_of   :login, :email, :case_sensitive => false
  validates_format_of       :email, :with => /(^([^@\s]+)@((?:[-_a-z0-9]+\.)+[a-z]{2,})$)|(^$)/i
 
  has_many :permissions
  has_many :roles, :through => :permissions
  has_many :user_profiles, :dependent => :destroy
  has_many :temp_metapackages, :dependent => :destroy
  belongs_to :distribution
  belongs_to :derivative
  belongs_to :language
  has_many :user_packages 
  has_many :selected_packages, :through => :user_packages, :source => :base_package, \
      :conditions => "user_packages.is_selected = 't'"    
  has_many :deselected_packages, :through => :user_packages, :source => :base_package, \
      :conditions => "user_packages.is_selected = 'f'"    
#  has_many :selected_metapackages, :through => :user_packages, :source => :base_package, \
#      :conditions => 'user_packages.base_package.class == Metapackage AND user_packages.is_selected'    
#  has_many :unselected_metapackages, :through => :user_packages, :source => :package_id, \
#      :conditions => 'user_packages.base_package.class == Metapackage && not user_packages.is_selected'    

  before_save :encrypt_password
  before_create :make_activation_code
  
  def self.template_users
    template_role = Role.find(:first, :conditions => ["rolename = ?",'template'])
    ps = Permission.find(:all,:conditions => ["role_id = ?",template_role.id])
    ps.map {|p| p.user}
  end
  
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :login, :email, :password, :password_confirmation
 
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
 
# auxilary method creating inital data for UserPackage table
  def self.init_user_package
    User.find(:all).each do |u| 
      if ! u.distribution_id.nil? then
        u.update_data
      end  
    end
  end
  
  def update_data 
    # update the data for all the main categories
    Category.find(1).children.each do |child|
      up = UserProfile.find(:first, :conditions => ["user_id = ? and category_id = ?",self.id,child.id])
      if up.nil? then val = 0 else val = up.rating end
      update_rating(child,val)
    end
  end
  
  # update the rating for a category and all its children
  def update_rating(cat,val)
    if val.nil? then val = 0 end
    uid = self.id
    cid = cat.id
    up = UserProfile.find(:first, :conditions => ["user_id = ? and category_id = ?",uid,cid])
    if up.nil? then 
      up = UserProfile.create(:user_id => uid, :category_id => cid, :rating => val)
    end
      if up.rating.nil? then upval = 0 else upval = up.rating end
      # if rating is new, then re-compute metapackage selection
      metas = Metapackage.find(:all, :conditions => ["category_id = ? and distribution_id = ? and license_type <= ?", \
               cid, self.distribution.id, self.license])
      metas.each do |m|
        update_meta(m,m.rating <= upval)
      end
      # also recursively update all the children
      cat.children.each do |child|
        update_rating(child,val)
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
