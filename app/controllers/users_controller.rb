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
  
  def title
    t(:view_layouts_application_21)
  end 
  layout 'application'
  
  before_filter :not_logged_in_required, :only => [:new, :create, :anonymous_login], :add_flash => { :notice => I18n.t(:controller_sessions_1) } 
  before_filter :login_required, :only => [:show, :edit, :update, :disable, :destroy, :enable, :metapackages]
  before_filter :check_administrator_role, :only => [:index, :destroy, :enable, :disable, :user_statistics, :spam_users_delete], :add_flash => { :notice => I18n.t(:no_admin) }
  
  helper :users
    
  def index
    @users = User.find_users(params[:page])                        
    @u = User.find(:all, :conditions => {:anonymous => false, :enabled => true})
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
    if request.env["HTTP_REFERER"].include?("session/new")
      redirect_to "/home"
    else
      redirect_to :back
    end  
  rescue ActiveRecord::RecordInvalid
    # release lock
    system "dotlockfile -u #{RAILS_ROOT}/anolock"
    flash[:error] = t(:controller_users_4)
    render :action => 'new'
  end

  def edit
    @user = current_user
  end

  def spam_users_delete
   # delete the spam users - only for manual start
   system("grep -C 10 \"No action responded to users\" #{RAILS_ROOT}/log/production.log|grep -o [A-Za-z0-9_-]*@[A-Za-z0-9_.-]* > ~/spam_users.txt")
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
  
  def destroy
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
        redirect_to :back
    else
        redirect_to :action => :show, :id => @user.id
    end
  end
end
