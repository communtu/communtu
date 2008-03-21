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
      
      
      out += "<div class='inner1' style='max-width:50%;'><table  width='
      100%'><tr><td>By: " +\
          c.user.login + "</td><td align='right'>" + link + "</td></tr><tr><td colspan='2'><hr/>" +\
          c.comment + "</td></tr></table></div>"
    end
    return out
  end
end
