class SessionsController < ApplicationController
  def title
    t(:view_layouts_application_21)
  end
  layout 'application'
  before_filter :login_required, :only => :destroy
#  before_filter :not_logged_in_required, :only => [:new, :create]
  
  # render new.rhtml
  def new
    if logged_in?
      flash[:error] = t(:controller_sessions_1)
      redirect_to "/home"
    end
  end
 
  def show
    redirect_to :action => 'new'
  end
  
  def create
    if logged_in?
      flash[:error] = t(:controller_sessions_1)
      redirect_to "/home"
      return
    end
    password_authentication(params[:login], params[:password])
    # check if distribution still exists
    if logged_in? and current_user.distribution.nil? then
      while current_user.distribution.nil?
        current_user.distribution_id += 1
        current_user.save
      end  
      flash[:error] = t(:controller_sessions_3,{:dist_old=>current_user.distribution.short_name,:dist_new=>current_user.distribution.name})
    end
  end
 
  def destroy
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    
    if editing_metapackage?
        Cart.find(session[:cart]).destroy
    end
    
    self.current_user.first_login = 0
    self.current_user.save!
    
    reset_session
       flash[:notice] = t(:controller_sessions_4)
  redirect_to "/home"
  end
  
  protected
  
  # Updated 2/20/08
  def password_authentication(login, password)
    user = User.authenticate(login, password)
    if user == nil
      failed_login(t(:controller_sessions_5))
    elsif user.activated_at.blank?  
      failed_login(t(:controller_sessions_6))
    elsif user.enabled == false
      failed_login(t(:controller_sessions_7))
    else
      self.current_user = user
      if editing_metapackage?
        Cart.find(session[:cart]).destroy
      end
      successful_login
    end
  end
  
  private
  
  def failed_login(message)
    flash[:notice] = message
    render :action => 'new'
  end
  
  def successful_login
    if params[:remember_me] == "1"
      self.current_user.remember_me
      cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
    end
      return_to = session[:return_to]
      if return_to.nil?
        if self.current_user.first_login == 1
            redirect_to user_user_profile_path(self.current_user) + "/tabs/0"
        else
            redirect_to "/home"
        end
      else
        redirect_to return_to
      end
  end
 
end
