module TempMetapackagesHelper

    def get_meta_cart
      temp = TempMetapackage.find(:first, :conditions => ["user_id=? AND id=?", current_user.id,\
        session[:meta_cart] ], :order => "name")
      
      if not temp.nil?
        contents = TempMetacontent.find(:all, :conditions => ["temp_metapackage_id=?", temp.id ])
        packages = Array.new
        contents.each do |c|
          p = Package.find(c.package_id)
          if not p.nil?
            packages.push p
          end
        end
        
       return packages
      end
      
      return []
    end

end
