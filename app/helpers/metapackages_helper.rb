module MetapackagesHelper

  def show_comments comments
    out = ""
    comments.each do |c|      
      out += "<div class='inner1' style='max-width:80%;'><table  width='
      100%'><tr><td>"+
          c.user.login + " - " + change_date_time(c.created_at).to_s + "</td><td align='right'>" + "</td></tr><tr><td colspan='2'><hr/>" +\
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
