# deprecated code, but should be reactivated

require 'tabz'

class UserProfileTabz < Tabz::Base

    resides_in "/users/:user_id/user_profile/tabs"
    
    add_tab do 
        titled "Grunddaten"
        looks_like "user_profiles/profile_data"
        with_data do
            map = {}
            if @user_data != :false then
              @user_data.user_profiles.each do |profile|
                map.store(profile.category_id, profile.rating!=0)
            end
            else
              UserProfile.find(:all).each do |profile|
                map.store(profile.category_id, false)
              end
            end
            set_to({ :distributions => Distribution.find(:all), :root => Category.find(1), :ratings => map })
        end
    end
    
    add_tab do
        titled "Detailauswahl"
        looks_like "user_profiles/profile_rating"
        with_data do
            selection    = []
            distribution = nil
            if @user_data != :false then
              selection = @user_data.selected_packages
              distribution = @user_data.distriubtion
            else
              distribution = session[:distriubtion]
              session[:profile].each do |category, value|
                metas = Metapackage.find(:all, :conditions => ["category_id = ? and distribution_id = ? and license_type <= ? and rating <= ?", \
                                                       category, distribution, session[:license], value])
                selection += metas
              end
            end
            set_to({ :root => Category.find(1), :selection => selection, :distribution => distribution })
        end
    end
    
    add_tab do
        titled "Installation durchführen"
        looks_like "user_profiles/installation"
        with_data do
          
        end
    end

end
