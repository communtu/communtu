class ApplicationController < ActionController::Base
  protect_from_forgery
 require 'lib/authenticated_system.rb'
 include AuthenticatedSystem

def do_anonymous_login(forced=false)
    cookies.delete :auth_token
    # create a lock in order to avoid concurrent creation of anonymous users
    system "dotlockfile #{Rails.root.to_s}/anolock"    
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
    system "dotlockfile -u #{Rails.root.to_s}/anolock"
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
