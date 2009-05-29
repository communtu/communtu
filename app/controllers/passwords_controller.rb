class PasswordsController < ApplicationController
  def title
    t(:controller_passwords_0)
  end
  layout 'application'
  before_filter :not_logged_in_required, :only => [:new, :create]
  
  # Enter email address to recover password 
  def new
  end
 
  # Forgot password action
  def create    
    return unless request.post?
  if @user = User.find_for_forget(params[:email])
      @user.forgot_password
      @user.save      
      flash[:notice] = t(:controller_passwords_1)
    redirect_to login_path
    else
      flash[:notice] = t(:controller_passwords_2)
      render :action => 'new'
    end  
  end
  
  # Action triggered by clicking on the /reset_password/:id link recieved via email
  # Makes sure the id code is included
  # Checks that the id code matches a user in the database
  # Then if everything checks out, shows the password reset fields
  def edit
    if params[:id].nil?
      render :action => 'new'
      return
    end
    @user = User.find_by_password_reset_code(params[:id]) if params[:id]
    raise if @user.nil?
  rescue
    logger.error t(:controller_passwords_3)
    flash[:notice] = t(:controller_passwords_4)
    #redirect_back_or_default('/')
    redirect_to new_user_path
  end
    
  # Reset password action /reset_password/:id
  # Checks once again that an id is included and makes sure that the password field isn't blank
  def update
    if params[:id].nil?
      render :action => 'new'
      return
    end
    if params[:password].blank?
      flash[:notice] = t(:controller_passwords_5)
      render :action => 'edit', :id => params[:id]
      return
    end
    @user = User.find_by_password_reset_code(params[:id]) if params[:id]
    raise if @user.nil?
    return if @user unless params[:password]
      if (params[:password] == params[:password_confirmation])
      #Uncomment and comment lines with @user to have the user logged in after reset - not recommended
        #self.current_user = @user #for the next two lines to work
        #current_user.password_confirmation = params[:password_confirmation]
        #current_user.password = params[:password]
        #@user.reset_password
    #flash[:notice] = current_user.save ? "Password reset" : "Password not reset"
    @user.password_confirmation = params[:password_confirmation]
    @user.password = params[:password]
    @user.reset_password        
    flash[:notice] = @user.save ? t(:controller_passwords_6) : t(:controller_passwords_7)
      else
        flash[:notice] = t(:controller_passwords_8)
        render :action => 'edit', :id => params[:id]
      return
      end  
      redirect_to login_path
  rescue
    logger.error t(:controller_passwords_9)
    flash[:notice] = t(:controller_passwords_10)
    redirect_to new_user_path
  end
    
end
