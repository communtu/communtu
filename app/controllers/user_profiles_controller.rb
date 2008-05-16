require 'user_meta_tabz'

class UserProfilesController < ApplicationController
  
  before_filter :authorize_user_subresource
  
  helper :user_profiles  
  helper :tabz
    
  def edit
  end
  
  def update_data
    user = current_user
    user.security = params[:sec]
    user.license  = params[:lic]
    user.distribution_id = params[:distribution]
    user.save!
    
    if current_user.first_login
        redirect_to user_user_profile_path(current_user) + "/tabs/1"
    else
        redirect_to user_user_profile_path(current_user) + "/tabs/0"
    end
  end
  
  def update_rating

    was_first = current_user.first_login
      
    current_user.first_login = 0
    current_user.save!
  
    params[:post].each do |key, value|
      profile = UserProfile.find(:first, :conditions => ["category_id= ? and user_id= ?", key.to_s, current_user.id])
      if not profile.nil?
        profile.update_attributes({:rating => value})
      else
        profile = UserProfile.new
        profile.rating = value
        profile.category_id = key
        profile.user_id = params[:user_id]
        profile.save!
      end
    end
    if was_first == 1
        redirect_to "/home"
    else
        redirect_to user_user_profile_path(current_user) + "/tabs/1"
    end    
  end
  
end
