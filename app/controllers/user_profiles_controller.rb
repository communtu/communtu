class UserProfilesController < ApplicationController
  
  before_filter :authorize_user_subresource
    
  def edit
    @user = current_user
    @root = Category.find(:first, :conditions => "id = '1'")
    @distributions = Distribution.find(:all, :order => "name")
      
    @rank_map = {}
    @user.user_profiles.each do |profile|
      @rank_map.store profile.category_id, profile.rating
    end
  end
  
  def update
    
    post = params[:post]
    user = current_user
    #user.update_attributes({ :security => params[:sec], :license => params[:lic] })
    user.security = params[:sec]
    user.license  = params[:lic]
    user.distribution_id = params[:distribution]
    user.save false
    
    post.each do |key, value|
      profile = UserProfile.find(:first, :conditions => ["category_id= ? and user_id= ?", key.to_s, current_user.id])
      if not profile.nil?
        profile.update_attributes({:rating => value})
      else
        profile = UserProfile.new
        profile.rating = value
        profile.category_id = key
        profile.user_id = params[:user_id]
        profile.save
      end
      profile = nil
    end
    flash[:notice] = 'User Profile saved succesfully!'
    redirect_to :controller => :users, :action => :desc, :id => current_user
  end
  
end
