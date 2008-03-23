require 'tabz'

class UserMetaTabz < Tabz::Base

    resides_in "/metapackages"

    add_tab do
        titled "Meine Metapakete"
        looks_like "metapackages/metalist"
        with_data do 
            set_to({ :packages => Metapackage.find(:all, :conditions => ["user_id=? AND distribution_id=?", @user_data.id, 
                @user_data.distribution_id]) })
        end
    end
    
    add_tab do
        titled "Alle Metapakete"
        looks_like "metapackages/metalist"
        with_data do 
            set_to({ :packages => Metapackage.find(:all, :conditions => ["distribution_id=? AND published=?", @user_data.distribution_id, 
                Metapackage.state[:published]]) })
        end
    end
end
