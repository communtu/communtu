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
        if is_admin?
          link = (link_to (repo.url + " " + repo.subtype), { :controller => :repositories, :action => :edit,\
            :id => repo.id, :distribution_id => repo.distribution_id })
          sync_link = (link_to (tag "img", { :src => "/images/view-refresh.png", :width => "22", :height => "22",\
            :alt => "Synchronize repository", :class => "link_img"}) ,\
            { :controller => :admin, :action => :sync_package, :id => repo.id})
          del_link =  (link_to (tag "img", { :src => "/images/edit-delete.png", :width => "22", :height => "22",\
            :alt => "Delete repository", :class => "link_img"}) ,\
             "/distributions/#{repo.distribution_id}/repositories/#{repo.id}/destroy")
          row = "<tr><td class='" + css + "' valign='middle'>" + sync_link +\
             "</td><td class='" + css + "' valign='middle'>" + link + "</td>" +\
             "<td class='" + css + "' valign='middle'>" + del_link + "</td></tr>"
        else
           row = "<tr><td class='" + css + "'><i>" + repo.url + " " + repo.subtype  + "</i></td></tr>"
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
    dist.name + "</span><p>" + dist.description + "</p>" + \
    "<b>Packages: " + dist.packages.size.to_s + "</b><br/>"
    
    if with_buttons
     out += (link_to 'Anzeigen', dist) + " | " + (link_to 'Bündel anzeigen', distribution_metapackages_path(dist.id)) +\
      " | " + (link_to 'Alle Pakete anzeigen', (distribution_packages_path dist.id))
      
    
      if is_admin?
        out += " | " + (link_to 'Bearbeiten', edit_distribution_path(dist)) + " | " +\
        (link_to 'Löschen', dist, :confirm => 'Bist du sicher?', :method => :delete)
      end
    end
    out + "</div>"
  end
end
