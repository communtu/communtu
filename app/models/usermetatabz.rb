class UserMetaTabz < Tabz::Base

    add_tab do
        titled "Meine Metapakete"
        looks_like "metapackages/metalist"
        with_data do
            set_to { :packages => Metapackage.find(:all, :conditions => ["user_id=?", current_user.id]) }
        end
    end
    
    add_tab do
        titled "Alle Metapakete"
        looks_like "metapackages/metalist"
        with data do
            set_to { :packages => Metapackage.find(:all, :conditions => ["distribution_id=? AND published=?", \
                current_user.distribution_id, Metapackage.state[:published]]) }
        end
    end
end
