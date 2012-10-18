# (c) 2008-2011 by Allgemeinbildung e.V., Bremen, Germany
# This file is part of Communtu.

# Communtu is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# Communtu is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero Public License for more details.

# You should have received a copy of the GNU Affero Public License
# along with Communtu.  If not, see <http://www.gnu.org/licenses/>.


class UsersController < ApplicationController
  # Be sure to include AuthenticationSystem in Application Controller instead
  

  def title
    t(:headline)
  end 
  layout 'application'
  
  before_filter :not_logged_in_required, :only => [:new, :create, :anonymous_login], :add_flash => { :notice => I18n.t(:controller_sessions_1) } 
  before_filter :login_required, :only => [:show, :edit, :update, :disable, :destroy, :enable, :metapackages]
  before_filter :check_administrator_role, :only => [:index, :destroy, :enable, :disable, :user_statistics, :spam_users_delete], :add_flash => { :notice => I18n.t(:no_admin) }
  
  helper :users
  
  
  # Protect these actions behind an admin login
  # before_filter :admin_required, :only => [:suspend, :unsuspend, :destroy, :purge]
  before_filter :find_user, :only => [:suspend, :unsuspend, :destroy, :purge]
  

  # render new.rhtml
  def new
    @user = User.new
  end
  
  def create_Rails2
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
    flash[:notice] = t(:controller_users_1)
    cookies[:backlink] = params[:form][:backlink]
    redirect_to "/session/new"
  rescue ActiveRecord::RecordInvalid
    flash[:error] = t(:controller_users_2)
    render :action => 'new'
  end

  def anonymous_login
    do_anonymous_login
    # prevent redirection to login page, which would give an error
    if session[:backlink] == nil
      redirect_to "/home"
    elsif session[:backlink].include?("session/new")
      redirect_to "/home"
    else
      redirect_to session[:backlink]
    end  
  rescue ActiveRecord::RecordInvalid
    # release lock
    system "dotlockfile -u #{Rails.root.to_s}/anolock"
    flash[:error] = t(:controller_users_4)
    render :action => 'new'
  end

  def edit
    if is_admin? && current_user.id != params[:id] then
      @user = User.find(params[:id])
    else
      @user = current_user
    end
  end

  def spam_users_delete
   # delete the spam users - only for manual start
   system("grep -C 10 \"No action responded to users\" #{Rails.root.to_s}/log/production.log|grep -o [A-Za-z0-9_-]*@[A-Za-z0-9_.-]* > ~/spam_users.txt")
    f = File.open('/home/communtu/web2.0/spam_users.txt')  
      while not f.eof? do  
          email = f.gets
          email = email.gsub("\n","")
          if User.find(:first, :conditions => {:email => email}).nil? then
             ud = ""
          else
             ud = User.find(:first, :conditions => {:email => email}) 
          end 
            if ud.id != ""
                User.delete(ud.id)
            end                   
      end  
    flash[:notice] = t(:spam_user_delete)
    redirect_to '/home'            
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
  
  def destroy_Rails2
    @user = User.find(params[:id])
    if @user.update_attribute(:enabled, false)
      flash[:notice] = t(:controller_users_8)
    else
      flash[:error] = t(:controller_users_9)
    end
    redirect_to :action => 'index'
  end
 
  def selfdestroy
    @user = User.find(params[:id])
    if @user.update_attribute(:enabled, false)
      flash[:notice] = t(:controller_users_8)
    else
      flash[:error] = t(:controller_users_9)
    end
    redirect_to '/logout'
  end                                     
 
  def delete
    @user = User.find(params[:id])
    @user.delete
#    if @user.update_attribute(:enabled, false)
#      flash[:notice] = t(:controller_users_10)
#    else
#      flash[:error] = t(:controller_users_11)
#    end
#    redirect_to '/logout'
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
   
  def desc   
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

  def search
    @user = User.find_by_login(params[:login])
    if @user.nil? then
        flash[:error] = t(:user_not_found)
        redirect_to session[:backlink]
    else
        redirect_to :action => :show, :id => @user.id
    end
  end

  def index
    @users = User.find_users(params[:page])   
    puts "HALLO1"                     
    @u = User.find(:all, :conditions => {:anonymous => false, :enabled => true})   
    puts "HALLO2"   
  end
 
   #This show action only allows users to view their own profile
  def show
    @user = User.find(params[:id])
    @metas_user = @user.metapackages
    userlog = Userlog.find(:last, :conditions => {:user_id => params[:id]})
    if userlog == nil
      @last_action = @user.updated_at
    else
      @last_action = userlog.created_at
    end
  end

###################################### below is rails3 code

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
    flash[:notice] = t(:controller_users_1)
#    cookies[:backlink] = params[:form][:backlink]
    redirect_to "/session/new"
  rescue ActiveRecord::RecordInvalid
    flash[:error] = t(:controller_users_2)
    render :action => 'new'


   # logout_keeping_session!
   # @user = User.new(params[:user])
   # @user.register! if @user && @user.valid?
   # success = @user && @user.valid?
   # if success && @user.errors.empty?
   #   redirect_back_or_default('/', :notice => "Thanks for signing up!  We're sending you an email with your activation code.")
   # else
   #   flash.now[:error]  = "We couldn't set up that account, sorry.  Please try again, or contact an admin (link is above)."
   #   render :action => 'new'
   # end
  end

  def activate
    logout_keeping_session!
    user = User.find_by_activation_code(params[:activation_code]) unless params[:activation_code].blank?
    case
    when (!params[:activation_code].blank?) && user && !user.active?
      user.activate!
      redirect_to '/login', :notice => "Signup complete! Please sign in to continue."
    when params[:activation_code].blank?
      redirect_back_or_default('/', :flash => { :error => "The activation code was missing.  Please follow the URL from your email." })
    else 
      redirect_back_or_default('/', :flash => { :error  => "We couldn't find a user with that activation code -- check your email? Or maybe you've already activated -- try signing in." })
    end
  end

  def suspend
    @user.suspend! 
    redirect_to users_path
  end

  def unsuspend
    @user.unsuspend! 
    redirect_to users_path
  end

  def destroy
    @user.delete!
    redirect_to users_path
  end

  def purge
    @user.destroy
    redirect_to users_path
  end
  
  # There's no page here to update or destroy a user.  If you add those, be
  # smart -- make sure you check that the visitor is authorized to do so, that they
  # supply their old password along with a new one to update it, etc.

  protected

  def find_user
    @user = User.find(params[:id])
  end

end
