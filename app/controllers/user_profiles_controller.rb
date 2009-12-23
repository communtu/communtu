require 'user_meta_tabz'

class UserProfilesController < ApplicationController
  def title
    t(:controller_profiles_0)
  end  
  
  helper :user_profiles  
  helper :tabz
    
  def edit
    if check_login then return end
  end
  
  def refine
    if check_login then return end
    params[:id] = 1
  end
  
  def sources
    if check_login then return end
    params[:id] = 2
  end

  def installation
    if check_login then return end
    params[:id] = 3
  end
  

  # update the basic data of the user's software selection
  def update_data 
    if check_login then return end

    # update other user data before updating profile so changes take effect
    user = current_user
    uparams = params[:user]
    user.first_login = 0
    # we cannot use update_attributes here...
    user.security = uparams[:security]
    user.license  = uparams[:license]
    user.distribution_id = uparams[:distribution_id]
    user.derivative_id = uparams[:derivative_id]
    user.architecture_id = uparams[:architecture_id]
    newly_advanced = !user.advanced and uparams[:advanced]
    user.advanced = uparams[:advanced]
    user.profile_changed = true
    user.save!
    if newly_advanced then
      redirect_to user_user_profile_path(current_user) + "/tabs/2"
    else
      redirect_to user_user_profile_path(current_user) + "/refine"
    end
  end
  
  def update_ratings
    if check_login then return end
    user = current_user
    user.first_login = 0
    user.profile_changed = true
    user.save!
    uid = user.id
    if (!params[:rough].nil?) or (!params[:rough_install].nil?) # update rough selection
      # get the list of categories selected via checkboxes
      if params[:categories].nil? then
        cats = []
      else
        cats = params[:categories].map {|s| s.to_i}
      end
      # update the data for all the main categories
      main_categories = Category.find(:all, :conditions => {:parent_id => 1, :main => true})
     # Category.find(1).children.each do |child|
        main_categories.each do |child|
        # we now use 1 for selected, in the future, this can be a boolean
        if cats.include? child.id then val = 1 else val = 0 end
        user.update_rating(child,val,user.license,user.security,{:anonymous => false, :session => session},false)
      end
    else # update fine grained selection
      #replace old list of packages...
      current_user.user_packages.each do |up|
        up.destroy
      end
      #... with new one from the form
      if params[:post].nil? then params[:post] = {} end
      params[:post].each do |key, value|
        if logged_in? then
          UserPackage.create(:user_id => uid, :package_id => key, :is_selected => true)
        else
          session[:profile][:key] = value
        end
      end
    end
    if (!params[:rough_install].nil?) or (!params[:fine_install].nil?) then
      redirect_to user_user_profile_path(current_user) + "/tabs/1"
    else
      redirect_to user_user_profile_path(current_user) + "/tabs/0"
    end
  end

  def create_livecd
    uid = params[:id]
    name = params[:name]
    err = Livecd.check_name(name)
    if !err.nil? then
      flash[:error] = err
      redirect_to user_user_profile_path(current_user) + "/tabs/3"
      #redirect_to ({:action => "livecd", :default_name => name})
      return
    end
    fork do
      system 'echo "User.find('+uid.to_s+').livecd(\''+name+'\')" > log/test1.log'
      system 'echo "User.find('+uid.to_s+').livecd(\''+name+'\')" | nohup script/console production'
    end
  end

  def test_livecd
    uid = params[:id]
    fork do
      system 'echo "User.find('+uid.to_s+').test_livecd" | nohup script/console production'
    end
    render :action => 'create_livecd'
  end

end
