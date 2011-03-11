# (c) 2008-2011 byllgemeinbildung e.V., Bremen, Germany
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

module DistributionsHelper
  
  #shows a repository in a div
  #params:
  #repos=dist to show
  #style=div-class

  def sync_link(repo)
    link_to((tag "img", { :src => "/images/view-refresh.png", :width => "22", :height => "22",\
            :alt => t(:helper_distributions_2), :title => t(:helper_distributions_2),:class => "link_img"}),\
            { :controller => :repositories, :action => :sync_package, :id => repo.id})
  end
  def force_sync_link(repo)
    link_to(t(:force_sync), 
            { :controller => :repositories, :action => :force_sync, :id => repo.id})
  end
  def mig_link(repo)
    link_to((tag "img", { :src => "/images/migrate.png", :width => "22", :height => "22",\
            :alt => t(:migrate_repository), :title => t(:migrate_repository),:class => "link_img"}) ,\
             "/repositories/migrate/#{repo.id}")
  end
  def del_link(repo)
    link_to((tag "img", { :src => "/images/edit-delete.png", :width => "22", :height => "22",\
            :alt => t(:helper_distributions_6), :title => t(:helper_distributions_6), :class => "link_img"}) ,\
             "/repositories/destroy/#{repo.id}")
  end

  def repository_view repos, style
    
    header = Array.new Package.security_types.length
    security_types = Package.security_types
    header.length.times do |i|
      header[i] = "<div class='" + style + "'><b>" + security_types[i] + ":</b><br/><table cellspacing='0' width='100%'>"
    end
    
    repos.each do |repo|
        css = cycle("packageList0", "packageList1")
        pic = if repo.license_type == 0 and repo.security_type == 0 then "tux_canonical.png"
              elsif repo.license_type == 0 and repo.security_type == 1 then "tux_community.png"
              elsif repo.license_type == 0 and repo.security_type == 2 then "tux_free.png"
              elsif repo.license_type == 1 and repo.security_type == 0 then "non_free_canonical.png"
              elsif repo.license_type == 1 and repo.security_type == 1 then "non_free_community.png"
              else "non_free.png"
              end
        title = if repo.license_type == 0 and repo.security_type == 0 then t(:helper_distributions_16)
              elsif repo.license_type == 0 and repo.security_type == 1 then t(:helper_distributions_17)
              elsif repo.license_type == 0 and repo.security_type == 2 then t(:helper_distributions_18)
              elsif repo.license_type == 1 and repo.security_type == 0 then t(:helper_distributions_19)
              elsif repo.license_type == 1 and repo.security_type == 1 then t(:helper_distributions_20)
              else t(:helper_distributions_21)
              end
      #  pic = if repo.license_type == 0 then "Tux2.png" else "24-security-lock.png" end
        #title = if repo.license_type == 0 then t(:helper_distributions_0) else t(:helper_distributions_1) end
        image = '<img border="0" height=24 src="/images/'+pic+'" title="'+title+'"/>'
        link = (link_to (repo.url + " " + repo.subtype), { :controller => :repositories, :action => :show,\
          :id => repo.id, :distribution_id => repo.distribution_id })
        if is_admin?
          row = "<tr><td class='" + css + "' valign='middle'>" + sync_link(repo) +\
             "</td><td class='" + css + "' valign='middle'>" + image + link + "</td>" +\
             "<td class='" + css + "' valign='middle'>" + mig_link(repo) + "&nbsp;&nbsp;" + del_link(repo) + "</td></tr>"
        else
           row = "<tr><td class='" + css + "'>" + image + link + "</td></tr>"
        end
        
        header[repo.security_type] += row
    end
    
    return (header.join "</table></div>") + "</table></div>" 
  end
  
  #shows a dist in a div
  #params:
  #dist=dist to show
  #style=div-class
  #with_buttons=should buttons be displayed?
  def dist_show dist, style, with_buttons = true
    out = "<div class='" + style + "'><span class='headline'>" +\
      dist.name + "</span><p>" + dist.description + "</p>"      
      #  (if dist.url.nil? then dist.name else (link_to dist.name, dist.url, :target=>'_blank') end)+\
    if !dist.predecessor.nil? then
      out += t(:predecessor)+": "+link_to(dist.predecessor.short_name,distribution_path(dist.predecessor))+"<br />"
    end
    if with_buttons
     out += (link_to t(:helper_distributions_8)+ if is_admin? then t(:helper_distributions_10) else "" end, dist)
      if is_admin?
        out += t(:helper_distributions_11) + (link_to t(:helper_distributions_12), edit_distribution_path(dist)) + " | " +\
        (link_to t(:helper_distributions_13), dist, :confirm => t(:view_distributions_show_8), :method => :delete)
        noreps = Repository.find_by_distribution_id(dist.id).nil?
        nobundles = MetacontentsDistr.find_by_distribution_id(dist.id).nil?
        if noreps | nobundles | dist.invisible | dist.preliminary then
          out += "<p><b>" + t(:steps_for_distribution_setup) + "</b></p><ul>"
          if noreps then
            out += "<li>" + (link_to t(:migrate_repositories), "/distributions/migrate/"+dist.id.to_s)+"</li>"
          end
          if nobundles then
            out += " <li> " + t(:wait_for_sync)
            if dist.repositories.map{|r| r.all_synchronized?}.all?
              out += "&nbsp;OK"
            end
            out += " </li>"
            out += "<li> " + (link_to t(:migrate_bundles), "/distributions/migrate_bundles/"+dist.id.to_s)+"</li>"
          end
          if dist.invisible then
            out += " <li> " + t(:wait_for_debs) + "</li>"
            out += " <li> " + t(:prepare_livecd) + "</li>"
            if !Deb.find(:first,:conditions=>{:distribution_id => dist.id}).nil? && Deb.find(:first,:conditions=>{:distribution_id => dist.id,:generated=>false}).nil?
              out += "&nbsp;OK"
            end
            out += "<li> " + (link_to t(:make_distribution_visible), "/distributions/make_visible/"+dist.id.to_s)+"</li>"
          end
          if dist.preliminary then
            out += " <li> " + t(:prepare_livecd_contd) + "</li>"
            out += " <li> " + t(:wait_for_release) + "</li><li>" + (link_to t(:make_distribution_final), "/distributions/make_final/"+dist.id.to_s)+"</li>"
          end
          out += "</ul>"
        end
      end
     out += "<p></p>"
     out += (link_to t(:helper_distributions_15), dist.url, :target=>'_blank')
    end
    out + "</div>"
  end
end
