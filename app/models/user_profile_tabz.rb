# deprecated code, but should be reactivated

require 'tabz'

class UserProfileTabz < Tabz::Base

    resides_in "/users/:user_id/user_profile/tabs"
    
    add_tab do
        titled I18n.t(:model_user_profile_tabz_1)
        looks_like "user_profiles/profile_rating"
        with_data do
          if @user_data[:user].class==User then
            @ratings = {}
            @user_data[:user].user_profiles.each do |profile|
              @ratings.store(profile.category_id, profile.rating!=0)
            end
            set_to({ :root => Category.find(1), 
                     :ratings => @ratings,
                     :selection => @user_data[:user].selected_packages, 
                     :distribution => @user_data[:user].distribution })
          end
        end
    end
    
    add_tab do
        titled I18n.t(:model_user_profile_tabz_3)
        looks_like "user_profiles/installation"
        with_data do
          if @user_data[:user].class==User then
            set_to({ :metas => @user_data[:user].selected_packages.uniq.map{|m| m.debian_name}.join(",")})
          end
        end
    end

    add_tab do
        titled I18n.t(:model_user_profile_tabz_0)
        looks_like "user_profiles/profile_data"
        with_data do
          if @user_data[:user].class==User then
            set_to({:distributions => if @user_data[:user].advanced  
                                      then Distribution.find_all_by_invisible(false)
                                      else Distribution.find_all_by_preliminary_and_invisible(false,false) end,
                    :root => Category.find(1),
                    :dist_string => @user_data[:dist_string]})
          end
        end
    end

    add_tab do
        titled I18n.t(:sources)
        looks_like "user_profiles/sources"
        with_data do
          if @user_data[:user].class==User then
            metas = @user_data[:user].selected_packages
            dist = @user_data[:user].distribution
            license = @user_data[:user].license
            security = @user_data[:user].security
            sources = {}
            metas.each do |p|
              p.recursive_packages_sources sources, dist, license, security
            end
            set_to({ :sources => sources})
          end
        end
    end


end
