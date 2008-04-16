require 'tabz'

class UserProfileTabz < Tabz::Base

    resides_in "/users/:user_id/user_profile/tabs"
    
    add_tab do 
        titled "Grunddaten"
        looks_like "user_profiles/profile_data"
        with_data do
            set_to({ :distributions => Distribution.find(:all) })
        end
    end
    
    add_tab do
        titled "Profilbewertung"
        looks_like "user_profiles/profile_rating"
        with_data do
        
            map = {}
            @user_data.user_profiles.each do |profile|
                map.store(profile.category_id, profile.rating)
            end
            set_to({ :root => Category.find(1), :ratings => map })
        end
    end

end
