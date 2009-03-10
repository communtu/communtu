require 'user_meta_tabz'

class UserProfilesController < ApplicationController
  def title
    "Installation von Bündeln"
  end  
  before_filter :authorize_user_subresource
  
  helper :user_profiles  
  helper :tabz
    
  def edit
    @root = Category.find(1)
    @distributions = Distribution.find(:all)
    @ratings = {}
    if logged_in? then
      current_user.user_profiles.each do |profile|
        @ratings.store(profile.category_id, profile.rating!=0)
    end
    else
      Category.find(:all).each do |category|
        @ratings.store(category.id, ((not session[:profile].nil?) and (session[:profile][category.id] != 0)))
      end
    end
  end
  
  def refine
    @root = Category.find(1)
    @selection = []
    if logged_in? then
      @selection += current_user.selected_packages
      @distribution = current_user.distribution
    else
      @distribution = Distribution.find(session[:distribution])
      session[:profile].each do |category, value|
        if value == 0 then
          metas = []
        else
          metas = Metapackage.find(:all, :conditions => ["category_id = ? and license_type <= ? and default_install = ?", \
            category, session[:license], 1])
        end    
        @selection += metas
      end
    end
  end
  
  def installation
    @metas = current_user.selected_packages.uniq.map{|m| m.debian_name}.join(",")
  end
  
  # update the basic data of the user's software selection
  def update_data 
    user         = current_user
    lic          = params[:lic]
    sec          = params[:sec]
    distribution = params[:distribution]
    derivative   = params[:derivative]
    if logged_in? then
      user.first_login = 0

      # update other user data before updating profile so changes take effect
      user.security = sec
      user.license  = lic
      user.distribution_id = distribution
      user.derivative_id = derivative
      user.profile_changed = true
      user.save!
    else
      session[:profile]      = {}
      session[:distribution] = distribution
      session[:derivative]   = derivative
      session[:license]      = lic.to_i
      session[:security]     = sec.to_i
    end
    
    # get the list of categories selected via checkboxes
    if params[:categories].nil? then
      cats = []
    else
      cats = params[:categories].map {|s| s.to_i}
    end
    # update the data for all the main categories
    Category.find(1).children.each do |child|
      # we now use 1 for selected, in the future, this can be a boolean
      if cats.include? child.id then val = 1 else val = 0 end
      user.update_rating(child,val,lic,sec,{:anonymous => !logged_in?, :session => session},false)
    end

    if !params[:choose].nil?
        redirect_to user_user_profile_path(current_user) + "/refine"
    else
        redirect_to user_user_profile_path(current_user) + "/installation"
    end
  end
  
  def update_ratings
    if logged_in? then 
      current_user.first_login = 0
      user.profile_changed = true
      current_user.save!
      uid = current_user.id
      #replace old list of packages...
      current_user.user_packages.each do |up|
        up.destroy
      end
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
    redirect_to user_user_profile_path(current_user) + "/installation"
  end

end
