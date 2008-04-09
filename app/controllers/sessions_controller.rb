class SessionsController < ApplicationController
  layout 'application'
  before_filter :login_required, :only => :destroy
  before_filter :not_logged_in_required, :only => [:new, :create]
  
  # render new.rhtml
  def new
  end
 
  def create
    password_authentication(params[:login], params[:password])
  end
 
  def destroy
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    flash[:notice] = "Du wurdest abgemeldet."
  redirect_to "/home"
  end
  
  protected
  
  # Updated 2/20/08
  def password_authentication(login, password)
    user = User.authenticate(login, password)
    if user == nil
      failed_login("Dein Benutzername oder Passwort ist falsch.")
    elsif user.activated_at.blank?  
      failed_login("Dein Benutzerkonto wurde noch nicht aktiviert. Der Aktivierungscode wurde dir per Email zugeschickt.")
    elsif user.enabled == false
      failed_login("Dein Benutzerkonto wurde deaktiviert.")
    else
      self.current_user = user
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
        redirect_to "/home"
      else
        redirect_to return_to
      end
  end
 
end
