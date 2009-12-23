require 'user_meta_tabz'

class UsersController < ApplicationController
  
  def title
    t(:view_layouts_application_21)
  end 
  layout 'application'
  
  before_filter :not_logged_in_required, :only => [:new, :create] 
  before_filter :login_required, :only => [:show, :edit, :update, :disable, :distroy, :enable]
  before_filter :check_administrator_role, :only => [:index, :destroy, :enable, :disable, :user_statistics]
  
  helper :users
  helper :tabz
    
  def index
    @users = User.find(:all, :conditions => {:anonymous => false, :enabled => true})
  end
  
  #This show action only allows users to view their own profile
  def show
  #  @user = current_user
    @user = User.find(params[:id])
    @metas_user = Metapackage.find_all_by_user_id(params[:id])
  end
    
  # render new.rhtml
  def new
    @user = User.new
  end
 
  def create
    cookies.delete :auth_token
    @user = User.new(params[:user])
    browser_dist = Distribution.browser_distribution(request.env['HTTP_USER_AGENT'])    
    set_dist_and_arch(@user)
    @user.derivative = Derivative.default
    @user.enabled = true
    @user.activation_code = nil
    @user.activated_at = Time.now    
    @user.profile_version = 1
    if params[:announce] == "1" and I18n.locale.to_s == "de"
      system "echo \"\" | mail -s \"announce\" -c info@toddy-franz.de -a \"FROM: #{@user.email}\" communtu-announce-de+subscribe@googlegroups.com &"
    elsif params[:announce] == "1"
      system "echo \"\" | mail -s \"announce\" -c info@toddy-franz.de -a \"FROM: #{@user.email}\" communtu-announce-en+subscribe@googlegroups.com &"
    end
    if params[:discuss] == "1" and I18n.locale.to_s == "de"
      system "echo \"\" | mail -s \"discuss\" -c info@toddy-franz.de -a \"FROM: #{@user.email}\" communtu-discuss-de+subscribe@googlegroups.com &"
    elsif params[:discuss] == "1"
      system "echo \"\" | mail -s \"discuss\" -c info@toddy-franz.de -a \"FROM: #{@user.email}\" communtu-discuss-en+subscribe@googlegroups.com &"
    end
    @user.save!
    #Uncomment to have the user logged in after creating an account - Not Recommended
    #self.current_user = @user
    flash[:notice] = t(:controller_users_1)
    #redirect_to params[:form][:backlink]
    cookies[:backlink] = params[:form][:backlink]
    redirect_to "/session/new"
  rescue ActiveRecord::RecordInvalid
    flash[:error] = t(:controller_users_2)
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
    flash[:notice] = t(:controller_users_3,{:anonymous_user=>@user.login})
    
    #have the user logged in 
    self.current_user = @user
    redirect_to "/home/home"
  rescue ActiveRecord::RecordInvalid
    # release lock
    system "dotlockfile -u #{RAILS_ROOT}/anolock"
    flash[:error] = t(:controller_users_4)
    render :action => 'new'
  end

  def edit
    @user = current_user
  end
  
  def update
    @user = User.find(current_user)
    flash[:notice] = t(:controller_users_5)
    if @user.anonymous then
      if ((params[:password] == params[:password_confirmation]) && !params[:password_confirmation].blank?)
        @user.password_confirmation= params[:password_confirmation]
        @user.password= params[:password]        
        # make user non-anonymous
        @user.anonymous = false
        #Create Inbox when user is not anonymous anymore
        Folder.create!(:user_id =>@user.id, :name=>"Inbox", :created_at=>Time.now(), :updated_at=>Time.now())
        @user.save
        flash[:notice] = t(:controller_users_6)
      else
        flash[:notice] = ""
        flash[:error] = t(:passwd_no_match)
        @old_password = params[:old_password]
        render :action => 'edit'
        return
      end
    end  
    if @user.update_attributes(params[:user])
      redirect_to :action => 'show', :id => current_user
    else
      flash[:notice] = ""
      render :action => 'edit'
    end
  end
  
  def destroy
    @user = User.find(params[:id])
    if @user.update_attribute(:enabled, false)
      flash[:notice] = t(:controller_users_8)
    else
      flash[:error] = t(:controller_users_9)
    end
    redirect_to :action => 'index'
  end
 
  def delete
    @user = User.find(params[:id])
    if @user.update_attribute(:enabled, false)
      flash[:notice] = t(:controller_users_10)
    else
      flash[:error] = t(:controller_users_11)
    end
    redirect_to '/logout'
  end
  
  def enable
    @user = User.find(params[:id])
    if @user.update_attribute(:enabled, true)
      flash[:notice] = t(:controller_users_12)
    else
      flash[:error] = t(:controller_users_13)
    end
      redirect_to :action => 'index'
  end
  
  def metapackages
  end
  
  def desc   
  end

  def set_dist_and_arch(user)
    s = request.env['HTTP_USER_AGENT']
    user.distribution = Distribution.browser_distribution_with_default(s)
    user.architecture = Architecture.browser_architecture_with_default(s)
    user.save
  end
  
  def user_statistics
  @log = Userlog.find(:all, :order => "created_at DESC", :conditions => {:user_id => params[:id]})
  @user = User.find(params[:id])
  @users = User.find(:all, :conditions => {:anonymous => false})
  @statistics = Array.new
  c = 0
  @users.each do |u|
  @statistics << {:user_id => u.id, :counter => Userlog.find(:all, :order => "created_at DESC", :conditions => {:user_id => u.id}).length}
  c = c+1
  end
  end
  
end
