class AccountsController < ApplicationController
  def title
    _("Ubuntu-Linux an die individuellen Bedürfnisse anpassen")
  end
  layout 'application'
  before_filter :login_required, :except => :show
  before_filter :not_logged_in_required, :only => :show
 
  # Activate action
  def show
    # Uncomment and change paths to have user logged in after activation - not recommended
    #self.current_user = User.find_and_activate!(params[:id])
  User.find_and_activate!(params[:id])
    flash[:notice] = _("Dein Benutzerkonto wurde aktiviert! Du kannst dich nun einloggen.")
    redirect_to login_path
  rescue User::ArgumentError
    flash[:notice] = _('Aktivierungs-Code nicht gefunden. Bitte versuche, ein neues Benutzerkonto anzulegen.')
    redirect_to new_user_path 
  rescue User::ActivationCodeNotFound
    flash[:notice] = _('Aktivierungs-Code nicht gefunden. Bitte versuche, ein neues Benutzerkonto anzulegen.')
    redirect_to new_user_path
  rescue User::AlreadyActivated
    flash[:notice] = _('Bein Benutzerkonto wurde bereits aktiviert. Du kannst dich nun anmelden.')
    redirect_to login_path
  end
  
  def edit
  end
  
  # Change password action  
  def update
    
  return unless request.post?
    if User.authenticate(current_user.login, params[:old_password])
      if ((params[:password] == params[:password_confirmation]) && !params[:password_confirmation].blank?)
        current_user.password_confirmation= params[:password_confirmation]
        current_user.password= params[:password]        
        if current_user.save
          flash[:notice] = _("Passwort aktualisiert.")
          redirect_to root_path #profile_url(current_user.login)
        else
          flash[:error] = _("Es ist ein Fehler aufgetreten. Das Passwort wurde nicht geändert.")
          render :action => 'edit'
        end
      else
        flash[:error] = _("Das neue Passwort stimmt nicht mit der Bestätigung überein.")
        @old_password = params[:old_password]
        render :action => 'edit'      
      end
    else
      flash[:error] = _("Dein altes Passwort war inkorrekt.")
      render :action => 'edit'
    end 
  end
  
end
