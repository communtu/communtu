module DistributionsHelper
  
  #shows a repository in a div
  #params:
  #repos=dist to show
  #style=div-class
  def repository_view repos, style
    
    header = Array.new Package.security_types.length
    security_types = Package.security_types
    header.length.times do |i|
      header[i] = "<div class='" + style + "'><b>" + security_types[i] + ":</b><br/><table cellspacing='0' width='100%'>"
    end
    
    repos.each do |repo|
        css = cycle("packageList0", "packageList1")
        pic = if repo.license_type == 0 then "free.jpg" else "commercial.jpg" end
        image = '<img border="0" height=25 src="/images/'+pic+'"/>'
        link = (link_to (repo.url + " " + repo.subtype), { :controller => :repositories, :action => :show,\
          :id => repo.id, :distribution_id => repo.distribution_id })
        if is_admin?
          sync_link = (link_to (tag "img", { :src => "/images/view-refresh.png", :width => "22", :height => "22",\
            :alt => "Repository synchronisieren", :class => "link_img"}) ,\
            { :controller => :admin, :action => :sync_package, :id => repo.id})
          mig_link =  (link_to (tag "img", { :src => "/images/migrate.png", :width => "22", :height => "22",\
            :alt => "Repository migieren", :class => "link_img"}) ,\
             "/repositories/migrate/#{repo.id}")
          del_link =  (link_to (tag "img", { :src => "/images/edit-delete.png", :width => "22", :height => "22",\
            :alt => "Repository löschen", :class => "link_img"}) ,\
             "/repositories/destroy/#{repo.id}")
          row = "<tr><td class='" + css + "' valign='middle'>" + sync_link +\
             "</td><td class='" + css + "' valign='middle'>" + image + link + "</td>" +\
             "<td class='" + css + "' valign='middle'>" + mig_link + "&nbsp;&nbsp;" + del_link + "</td></tr>"
        else
           row = "<tr><td class='" + css + "'>" + link + "</td></tr>"
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
    
    if with_buttons
     out += "Quellen " + (link_to ' anzeigen '+ if is_admin? then "und bearbeiten" else "" end, dist)
      if is_admin?
        out += "<br />Distribution " + (link_to 'bearbeiten', edit_distribution_path(dist)) + " | " +\
        (link_to 'löschen', dist, :confirm => 'Bist du sicher?', :method => :delete)
      end
     out += "<p></p>"
     out += (link_to 'Wikiseite bei Ubuntuusers', dist.url, :target=>'_blank')
    end
    out + "</div>"
  end
end
