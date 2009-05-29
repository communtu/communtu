require 'user_meta_tabz'

class UserProfilesController < ApplicationController
  def title
    t(:controller_profiles_0)
  end  
  before_filter :authorize_user_subresource
  
  helper :user_profiles  
  helper :tabz
    
  def edit
  end
  
  def refine
    params[:id] = 1
  end
  
  def sources
    params[:id] = 2
  end

  def installation
    params[:id] = 3
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
      user.update_rating(child,val,lic,sec,{:anonymous => false, :session => session},false)
    end

    if !params[:choose].nil?
        redirect_to user_user_profile_path(current_user) + "/refine"
    else
        redirect_to user_user_profile_path(current_user) + "/installation"
    end
  end
  
  def update_ratings
    current_user.first_login = 0
    current_user.profile_changed = true
    current_user.save!
    uid = current_user.id
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
    redirect_to user_user_profile_path(current_user) + "/installation"
  end

end
