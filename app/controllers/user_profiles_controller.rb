require 'user_meta_tabz'

class UserProfilesController < ApplicationController
  def title
    t(:controller_profiles_0)
  end  
  
  helper :user_profiles  
  helper :tabz
    
  def edit
    if check_login then return end
    user = current_user
    @ratings = {}
    user.user_profiles.each do |profile|
      @ratings.store(profile.category_id, profile.rating!=0)
    end
    @root = Category.find(1)
    @selection = user.selected_packages
  end
  
  def settings
    if check_login then return end
    user = current_user
    @distributions = if user.advanced
                     then Distribution.find_all_by_invisible(false)
                     else Distribution.find_all_by_preliminary_and_invisible(false,false) end
    user_agent = request.env['HTTP_USER_AGENT']
    @dist_string = Distribution.browser_info(user_agent)+" "+
                   Architecture.browser_info(user_agent)
  end
  
  def sources
    if check_login then return end
    user = current_user
    metas = user.selected_packages
    dist = user.distribution
    license = user.license
    security = user.security
    @sources = {}
    metas.each do |p|
       p.recursive_packages_sources @sources, dist, license, security
    end
  end

  def installation
    if check_login then return end
    @metas = current_user.selected_packages.uniq.map{|m| m.debian_name}.join(",")
  end

  def livecd
    if check_login then return end
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
      redirect_to user_user_profile_path(current_user) + "/settings"
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
      redirect_to user_user_profile_path(current_user) + "/installation"
    else
      redirect_to user_user_profile_path(current_user) + "/edit"
    end
  end

  def create_livecd
    user = User.find(params[:id])
    name = params[:name]
    err = Livecd.check_name(name)
    if !err.nil? then
      flash[:error] = err
      #redirect_to ({:action => "livecd", :default_name => name})
      #return
    else
      flash[:notice] = t(:livecd_create)
      user.livecd(name)
    end
    redirect_to user_user_profile_path(current_user) + "/livecd"
  end

  def test_livecd
    uid = params[:id]
    pid = fork do
      system 'echo "User.find('+uid.to_s+').test_livecd" | nohup script/console production'
    end
    render :action => 'create_livecd'
  end

end
