# deprecated code, but should be reactivated

require 'tabz'

class UserProfileTabz < Tabz::Base

    resides_in "/users/:user_id/user_profile/tabs"
    
    add_tab do 
        titled "Grunddaten"
        looks_like "user_profiles/profile_data"
        with_data do
          @ratings = {}
          @user_data[:user].user_profiles.each do |profile|
            @ratings.store(profile.category_id, profile.rating!=0)
          end
          set_to({:distributions => Distribution.find(:all), 
                  :root => Category.find(1), 
                  :ratings => @ratings, 
                  :dist_string => @user_data[:dist_string]})
        end
    end
    
    add_tab do
        titled "Detailauswahl"
        looks_like "user_profiles/profile_rating"
        with_data do
            set_to({ :root => Category.find(1), 
                     :selection => @user_data[:user].selected_packages, 
                     :distribution => @user_data[:user].distribution })
        end
    end
    
    add_tab do
        titled "Installation durchführen"
        looks_like "user_profiles/installation"
        with_data do
            set_to({ :metas => @user_data[:user].selected_packages.uniq.map{|m| m.debian_name}.join(",")})          
        end
    end

end
