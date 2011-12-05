class ApplicationController < ActionController::Base
  protect_from_forgery def available_locales; AVAILABLE_LOCALES; end 
  
    before_filter :set_locale
    before_filter :log_ram # or use after_filter
    before_filter :save_backlink # because http_referrer isn't set anymore

  def log_ram
    logger.warn Process.pid.to_s + ': RAM USAGE: ' + `pmap #{Process.pid} | tail -1`[10,40].strip
  end

  def set_locale
    I18n.locale = extract_locale_from_subdomain
  end
  
  def save_backlink
    session[:backlink] = session[:current_uri]
    session[:current_uri] = request.request_uri()
  end

  def extract_locale_from_subdomain
    parsed_locale = request.host.split('.').first
    #firstparsed_locale = request.subdomains.first
    (AVAILABLE_LOCALES.include? parsed_locale) ? parsed_locale : nil
  end

  require 'set.rb'
  
  helper :all # include all helpers, all the time
  include AuthenticatedSystem
  include ApplicationHelper
  
  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '0b1deaf6bf7e9a53ea11187cd1bbe6a1'
  
  rescue_from ActionController::InvalidAuthenticityToken, :with => :auth_error
  
  def auth_error
    redirect_to(:controller => 'home', :action => 'auth_error')
  end
  filter_parameter_logging :password 
  
  def is_anonymous 
    if (!logged_in?) or current_user.anonymous?
      flash[:error] = t(:controller_application_0)
      redirect_to root_path
    end
  end

  # berfore_filters are useless, because path is /users/...
  def check_login
    if !logged_in? then
      flash[:error] = t(:lib_system_0)
      redirect_to "/home/home"
      return true
    else
      return false
    end
  end         

  def check_power_user_role
    check_role('power user')
  end    
  
  def check_livecd_enabled
    if !SETTINGS["livecd"]
      flash[:error] = t(:livecd_disabled)
      redirect_to session[:backlink]
    end  
  end
  
  def do_anonymous_login(forced=false)
    cookies.delete :auth_token
    # create a lock in order to avoid concurrent creation of anonymous users
    system "dotlockfile #{RAILS_ROOT}/anolock"    
    # create a unique new user name
    last_anonymous_user = User.find_all_by_anonymous(true)[-1]
    if last_anonymous_user.nil? then
      login = "a001"
    else
      login = last_anonymous_user.login.succ
    end
    while !User.find_by_login(login).nil? or !User.find_by_email(login+"@example.org").nil?
      login.succ!
    end
    @user = User.new(:login => login, :email => login+"@example.org",
                :password => login, :password_confirmation => login)
    browser_dist = Distribution.browser_distribution(request.env['HTTP_USER_AGENT'])
    set_dist_and_arch(@user)
    @user.derivative = Derivative.default
    @user.enabled = true
    @user.anonymous = true
    @user.activation_code = nil
    @user.activated_at = Time.now    
    @user.profile_version = 1
    @user.save!
    # release lock
    system "dotlockfile -u #{RAILS_ROOT}/anolock"
    flash[:notice] = if forced then t(:action_needs_login) else "" end
    flash[:notice] += " "+t(:controller_users_3,{:anonymous_user=>@user.login})
    
    #have the user logged in 
    self.current_user = @user

  end
  
  def set_dist_and_arch(user)
    s = request.env['HTTP_USER_AGENT']
    user.distribution = Distribution.browser_distribution_with_default(s)
    user.architecture = Architecture.browser_architecture_with_default(s)
    user.save
  end
  

end
