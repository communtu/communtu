require 'tabz'
require 'utils'

class UserMetaTabz < Tabz::Base

    resides_in "/users/:user_id/metapackages"
    
    add_tab do
        titled I18n.t(:model_user_meta_tabz_0)
        looks_like "metapackages/metalist"
        with_data do 
            result = sort_metalist(@user_data, 0) #owner
            set_to({ :packages => result })
        end
    end
    
    add_tab do
        titled I18n.t(:model_user_meta_tabz_1)
        looks_like "metapackages/metalist"
        with_data do              
          if @user_data[:user].has_role?('administrator') then
            result = sort_metalist(@user_data, 1) #admin
            set_to({ :packages => result })
          else  
            result = sort_metalist(@user_data, 2) #other
            set_to({ :packages => result })
          end
        end
    end
    
    add_tab do
        titled I18n.t(:model_user_meta_tabz_2)
        looks_like "packages/packagelist"
        with_data do
            set_to({ :packages => Package.find_packages(@user_data[:session][:search], 
                        @user_data[:session][:group], @user_data[:session][:programs],
                        @user_data[:params][:page]),
                     :distribution => @user_data[:user].distribution,
                     :groups => Package.find(:all, :select => "DISTINCT section", :order => "section") })
        end
    end
    
end
