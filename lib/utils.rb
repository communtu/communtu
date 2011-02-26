  def safe_system cmd
    if !system cmd
      raise I18n.t(:lib_utils_0)+cmd
    end
  end
  
  def sort_metalist(user_data, user_type) #USER_TYPE: 0 = owner, 1 = admin, 2 = other
    if(user_data[:params][:order].nil?)
      user_data[:params][:order] = "categories.name"
    end

    if(user_data[:params][:order] == "categories.name")
      if(user_type == 2)
          statement = Metapackage.find( :all, :conditions => ['published=?', true],:joins => 'LEFT JOIN categories ON base_packages.category_id = categories.id', :order =>user_data[:params][:order])
        elsif(user_type == 1)
          statement = Metapackage.find( :all, :joins => 'LEFT JOIN categories ON base_packages.category_id = categories.id', :order =>user_data[:params][:order])
        elsif(user_type == 0)
          statement = Metapackage.find( :all, :conditions => ["user_id=?", user_data[:user].id],:joins => 'LEFT JOIN categories ON base_packages.category_id = categories.id', :order =>user_data[:params][:order])
      end
      
      elsif(user_data[:params][:order] == "rating")
        if(user_type == 2)
          statement = Metapackage.find( :all,
            :select => "base_packages.*, avg(ratings.rating) AS rating",
            :joins => "LEFT JOIN ratings ON base_packages.id = ratings.rateable_id",
            :conditions => ["published=? AND ratings.rateable_type = 'BasePackage'", true],
            :group => "ratings.rateable_id",
            :order => "#{user_data[:params][:order]} DESC")
      
        elsif(user_type == 1)
          statement = Metapackage.find( :all,
            :select => "base_packages.*, avg(ratings.rating) AS rating",
            :joins => "LEFT JOIN ratings ON base_packages.id = ratings.rateable_id",
            :conditions => ["ratings.rateable_type = 'BasePackage'"],
            :group => "ratings.rateable_id",
            :order => "#{user_data[:params][:order]} DESC")
      
        elsif(user_type == 0)
          statement = Metapackage.find( :all,
            :select => "base_packages.*, avg(ratings.rating) AS rating",
            :joins => "LEFT JOIN ratings ON base_packages.id = ratings.rateable_id",
            :conditions => ["base_packages.user_id=? AND ratings.rateable_type = 'BasePackage'", user_data[:user].id],
            :group => "ratings.rateable_id",
            :order => "#{user_data[:params][:order]} DESC")
       end
      
      elsif(user_data[:params][:order] == "name")
        if(user_type == 2)
          statement = Metapackage.find( :all, :conditions => ['published=?', true], :order =>user_data[:params][:order])
        elsif(user_type == 1)
          statement = Metapackage.find( :all, :order =>user_data[:params][:order])
        elsif(user_type == 0)
          statement = Metapackage.find( :all, :conditions => ["user_id=?", user_data[:user].id], :order =>user_data[:params][:order])
      end
    end
    
    return statement
  end

   def translation(translatable_id)
     #I18n.locale.to_s
    tr=Translation.find(:first, :conditions => {:translatable_id => translatable_id, :language_code => I18n.locale.to_s })
    if tr.nil? then
      tr=Translation.find(:first, :conditions => {:translatable_id => translatable_id, :language_code => "en" })
        if tr.nil? then
          return "unknown"
        end
    end
    return tr.contents
  end

 def min(x,y)
    if x <= y then x else y end
 end

 def disk_used_space( path )
  `df -Pk #{path} |grep ^/ | awk '{print $3;}'`.
    to_i * 1.kilobyte
 end

 def disk_free_space( path )
  `df -Pk #{path} |grep ^/ | awk '{print $4;}'`.
    to_i * 1.kilobyte
 end