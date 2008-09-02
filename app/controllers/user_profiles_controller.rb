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
    # if template user has changed, update rating data
    if user.template_id.to_s != params[:template].to_s then
      # copy rating from template user
      UserProfile.find(:all, :conditions => ["user_id= ?", params[:template]]).each do |p|
        pold = UserProfile.find(:first,:conditions => ["category_id= ? and user_id= ?",p.category_id,user.id])
        if pold.nil? then
          UserProfile.create(:user_id => user.id, :category_id => p.category_id, :rating => p.rating)
        else
          pold.rating = p.rating
          pold.save
        end  
      end
    end
    user.template_id = params[:template]
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
