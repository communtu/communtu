require 'user_meta_tabz'

class UsersController < ApplicationController
  def title
    "Benutzerverwaltung"
  end 
  layout 'application'
  
  before_filter :not_logged_in_required, :only => [:new, :create] 
  before_filter :login_required, :only => [:show, :edit, :update, :disable, :distroy, :enable]
  before_filter :check_administrator_role, :only => [:index, :destroy, :enable, :disable]
  
  helper :users
  helper :tabz
    
  def index
    @users = User.find(:all)
  end
  
  #This show action only allows users to view their own profile
  def show
    @user = current_user
  end
    
  # render new.rhtml
  def new
    @user = User.new
  end
 
  def create
    cookies.delete :auth_token
    @user = User.new(params[:user])
    @user.enabled = true
    @user.activation_code = nil
    @user.activated_at = Time.now    
    @user.profile_version = 1
    @user.save!
    #Uncomment to have the user logged in after creating an account - Not Recommended
    #self.current_user = @user
    flash[:notice] = "Danke für die Registrierung bei Communtu! Du kannst dich jetzt anmelden."
    redirect_to "/session/new"
  rescue ActiveRecord::RecordInvalid
    flash[:error] = "Es gab ein Problem mit der Registrierung."
    render :action => 'new'
  end

  def anonymous_login
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
    @user.enabled = true
    @user.anonymous = true
    @user.activation_code = nil
    @user.activated_at = Time.now    
    @user.profile_version = 1
    @user.save!
    # release lock
    system "dotlockfile -u #{RAILS_ROOT}/anolock"
    flash[:notice] = "Du wurdest als Nutzer #{login} mit Kennwort #{login} eingeloggt. Bitte ggf. unter 'Benutzerkonto' in ein dauerhaftes Nutzerkonto umwandeln; ansonsten wird das Konto nach einem Tag wieder gelöscht."
    #have the user logged in 
    self.current_user = @user
    redirect_to "/home/home"
  rescue ActiveRecord::RecordInvalid
    # release lock
    system "dotlockfile -u #{RAILS_ROOT}/anolock"
    flash[:error] = "Es gab ein Problem mit der anonymen Nutzung."
    render :action => 'new'
  end

  def edit
    @user = current_user
  end
  
  def update
    @user = User.find(current_user)
    # make user non-anonymous
    @user.anonymous = false
    @user.save
    if @user.update_attributes(params[:user])
      flash[:notice] = "Benutzer aktualisiert"
      redirect_to :action => 'show', :id => current_user
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    @user = User.find(params[:id])
    if @user.update_attribute(:enabled, false)
      flash[:notice] = "Benutzer deaktiviert"
    else
      flash[:error] = "Es gab ein Problem mit der Deaktivierung dieses Benutzers."
    end
    redirect_to :action => 'index'
  end
 
  def delete
    @user = User.find(params[:id])
    if @user.update_attribute(:enabled, false)
      flash[:notice] = "Benutzer gelöscht"
    else
      flash[:error] = "Es gab ein Problem mit der Löschung."
    end
    redirect_to '/logout'
  end
  
  def enable
    @user = User.find(params[:id])
    if @user.update_attribute(:enabled, true)
      flash[:notice] = "Benutzer aktiviert"
    else
      flash[:error] = "Es gab ein Problem mit der Aktivierung dieses Benutzers."
    end
      redirect_to :action => 'index'
  end
  
  def metapackages
  end
  
  def desc   
  end
 
end
