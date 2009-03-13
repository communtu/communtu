require 'user_meta_tabz'

class UsersController < ApplicationController
  def title
    "Benutzerverwaltung"
  end 
  layout 'application'
  
  before_filter :not_logged_in_required, :only => [:new, :create] 
  before_filter :login_required, :only => [:show, :edit, :update]
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
  
  def edit
    @user = current_user
  end
  
  def update
    @user = User.find(current_user)
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
