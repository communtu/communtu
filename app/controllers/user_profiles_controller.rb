require 'user_meta_tabz'

class UserProfilesController < ApplicationController
  
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
        metas = Metapackage.find(:all, :conditions => ["category_id = ? and distribution_id = ? and license_type <= ? and rating <= ?", \
            category, @distribution.id, session[:license], value])
        @selection += metas
      end
    end
  end
  
  def installation
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
      update_rating(user,child,val,distribution,lic,sec)
    end

    if !params[:choose].nil?
        redirect_to user_user_profile_path(current_user) + "/refine"
    else
        redirect_to user_user_profile_path(current_user) + "/installation"
    end
  end
  
  # update the rating for a category and all its children
  def update_rating(user,cat,val,distribution,lic,sec)

    is_new = false
    cid    = cat.id

    if logged_in? then

      uid = user.id
      up  = UserProfile.find(:first, :conditions => ["user_id = ? and category_id = ?",uid,cid])

      if up.nil? then 
        up = UserProfile.create(:user_id => uid, :category_id => cid, :rating => val)
        # no profile yet - we are in a new situation
        is_new = true  
      else
        # if rating has changed, it is new...
        if up.rating != val then is_new = true end
        up.rating = val
        up.save
      end
    else
      is_new = true
      session[:profile].store(cid, val)
    end

    if is_new then
      # if rating is new, then re-compute metapackage selection
      metas = Metapackage.find(:all, :conditions => ["category_id = ? and distribution_id = ? and license_type <= ?", \
               cid, distribution, lic])
      metas.each do |m|
        if logged_in? then
          update_meta(uid,m,m.rating <= up.rating)
        end
      end
      # also recursively update all the children
      cat.children.each do |child|
        update_rating(user,child,val,is_new,lic,sec)
      end 
    end
  end
  
  # update meta package selection to default given by sel
  def update_meta(uid,m,sel)
    upk = UserPackage.find(:first, :conditions => ["user_id = ? and package_id = ?",uid,m.id])
    if upk.nil? then
      UserPackage.create(:user_id => uid,:package_id => m.id, :is_selected => sel)
    else
      upk.is_selected = sel
      upk.save
    end  
  end
  
  def update_ratings
    if logged_in? then 
      current_user.first_login = 0
      current_user.save!
      uid = current_user.id
      #replace old list of packages...
      current_user.user_packages.each do |up|
        up.destroy
      end
    end
    
    #... with new one from the form
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
