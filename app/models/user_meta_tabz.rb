require 'tabz'

class UserMetaTabz < Tabz::Base

    resides_in "/users/:user_id/metapackages"
    
    add_tab do
        titled "Meine Bündel"
        looks_like "metapackages/metalist"
        with_data do 
            set_to({ :packages => Metapackage.find(:all, :conditions => ["user_id=?", @user_data[:user].id])})
        end
    end
    
    add_tab do
        titled "Alle veröffentlichten Bündel"
        looks_like "metapackages/metalist"
        with_data do 
            set_to({ :packages => Metapackage.find(:all, :conditions => ["published=?", 
                Metapackage.state[:published]]) })
        end
    end
    
    add_tab do
        titled "Ubuntu-Pakete"
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
