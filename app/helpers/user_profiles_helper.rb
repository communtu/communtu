module UserProfilesHelper
  
  def node_is_leaf? node
    node.children.nil? or node.children.length == 0
  end
  
  def profile_radio_tag node, rating, value
    out = "<input type='radio' id='post' name='post[" + node.id.to_s + "]' value='" + value.to_s + "'"
    if (value == 0 and (rating.nil? or rating == value))
      out += " checked='checked' />"
    elsif (not rating.nil? and rating == value) 
      out += " checked='checked' />"
    else
      out += ">"
    end
    return out
  end
  
  def profile_table_column node, rating, value, css
    out  = "<td class='" + css + "' align='center' >"
    if node_is_leaf? node then out += profile_radio_tag node, rating, value end
    out += "</td>\n"
  end
    
  def profile_rows node, map, depth
    out    = ""
    node.children.each do |child|
      rating = map[child.id]
      out += "<tr>\n"
      out += "<td class='profileExpandCol'></td>"
      out += "<td class='profileNameCol" + depth.to_s + "' width='400'><b>" + child.name + "</b></td>\n"
      5.times do |n|
        css  = (if n == 4 then "profileRatingColRight" else "profileRatingCol" end)
        out += profile_table_column child, rating, n, css
      end
      out += "</tr>\n"
      if not child.children.nil?
        out += profile_rows child, map, (depth + 1)
      end
    end
    return out
  end   
  
  def edit_profile_table root, map
    table  = "<table class='profileTable' cellspacing='0'>\n"
    table += "<tr><th></th><th></th><th>&nbsp;gar nicht&nbsp;</th><th>&nbsp;normal&nbsp;</th><th>&nbsp;erweitert&nbsp;</th><th>&nbsp;Experte&nbsp;</th><th>&nbsp;Freak&nbsp;</th></tr>"
    table += profile_rows root, map, 0
    table += "</table>\n"
  end
  
end
