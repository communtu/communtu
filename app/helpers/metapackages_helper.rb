module MetapackagesHelper

  def show_comments comments
    out = ""
    comments.each do |c|
      if (not c.temp_metapackage_id.nil?) and c.temp_metapackage_id != 0
        link = link_to 'Attached Package', :controller => :temp_metapackages, :action => :show,\
          :id => c.temp_metapackage_id
      else
        link=""
      end
      
      
      out += "<div class='inner1' style='max-width:80%;'><table  width='
      100%'><tr><td>Von: " +\
          c.user.login + "</td><td align='right'>" + link + "</td></tr><tr><td colspan='2'><hr/>" +\
          c.comment + "</td></tr></table></div>"
    end
    return out
  end
  
  def get_category_select_options root, level = ""
      
      if not root.nil? and root.id != 1
        options = "<option value='" + root.id.to_s + "'>" +\
          level + " " + root.name + "</option>"
      
        level += "-"
      else
        options = ""
      end
      
      if not root.children.nil?
        root.children.each do |child|
          options += (get_category_select_options child, level)
        end
      end
      
      return options
    end

end
