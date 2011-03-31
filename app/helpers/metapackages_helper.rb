# (c) 2008-2011 by Allgemeinbildung e.V., Bremen, Germany
# This file is part of Communtu.

# Communtu is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# Communtu is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero Public License for more details.

# You should have received a copy of the GNU Affero Public License
# along with Communtu.  If not, see <http://www.gnu.org/licenses/>.

module MetapackagesHelper

  def show_comments comments
    out = ""
    comments.reverse.each do |c|      
      out += "<div class='inner1' style='max-width:80%;'><table  width='
      100%'><tr><td>"+
          c.user.login + " - " + change_date_time(c.created_at).to_s + "</td><td align='right'>" + "</td></tr><tr><td colspan='2'><hr/>" +\
          c.comment + "</td></tr></table></div>"
    end
    return out
  end
  
  def show_ratings_and_comments ratings
    out = ""
    ratings.reverse.each do |r|      
      out += "<b>#{t(:view_metapackages_show_comment_and_ratings)}</b><div class='inner1' style='max-width:80%;'><table  width='
      100%'><tr><td>"+
         "<div class='star-ratings-block'>" +
            "<ul class='star-rating' alt='#{r.rating} #{t(:view_rating_show_title_got_ratings)}' title='#{r.rating} #{t(:view_rating_show_title_got_ratings)}'>" +
                "<li class='current-rating' style='width:#{r.rating*25}px'></li>" +
            "</ul>" +
         "</div>"
       if !r.user.nil? 
         if r.user.enabled?
           out += r.user.login
         else
           out += "<strike>" + r.user.login + "</strike>"
         end  
       end
         out += " - " + change_date_time(r.created_at).to_s + "</td><td align='right'>" + "</td></tr><tr><td colspan='2'><hr/>" +\
         r.comment + "</td></tr></table></div>"
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

  def show_version meta
    if meta.version!=meta.debianized_version
      t(:view_metapackages_show_version_v, :v=> meta.version)
    else
      ""
    end
  end

  def show_debversion meta
    if meta.version!=meta.debianized_version
      t(:view_metapackages_show_version_v, :v=> meta.debianized_version)
    else
      ""
    end
  end

end
