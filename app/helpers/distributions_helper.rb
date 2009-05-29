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
        pic = if repo.license_type == 0 then "Tux2.png" else "24-security-lock.png" end
        title = if repo.license_type == 0 then "t(:helper_distributions_0)" else "t(:helper_distributions_1)" end
        image = '<img border="0" height=25 src="/images/'+pic+'" title="'+title+'"/>'
        link = (link_to (repo.url + " " + repo.subtype), { :controller => :repositories, :action => :show,\
          :id => repo.id, :distribution_id => repo.distribution_id })
        if is_admin?
          sync_link = (link_to (tag "img", { :src => "/images/view-refresh.png", :width => "22", :height => "22",\
            :alt => t(:helper_distributions_2), :title => t(:helper_distributions_3),:class => "link_img"}) ,\
            { :controller => :admin, :action => :sync_package, :id => repo.id})
          mig_link =  (link_to (tag "img", { :src => "/images/migrate.png", :width => "22", :height => "22",\
            :alt => t(:helper_distributions_4), :title => t(:helper_distributions_5),:class => "link_img"}) ,\
             "/repositories/migrate/#{repo.id}")
          del_link =  (link_to (tag "img", { :src => "/images/edit-delete.png", :width => "22", :height => "22",\
            :alt => t(:helper_distributions_6), :title => t(:helper_distributions_7), :class => "link_img"}) ,\
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
     out += t(:helper_distributions_8) + (link_to t(:helper_distributions_9)+ if is_admin? then t(:helper_distributions_10) else "" end, dist)
      if is_admin?
        out += t(:helper_distributions_11) + (link_to t(:helper_distributions_12), edit_distribution_path(dist)) + " | " +\
        (link_to t(:helper_distributions_13), dist, :confirm => t(:helper_distributions_14), :method => :delete)
      end
     out += "<p></p>"
     out += (link_to t(:helper_distributions_15), dist.url, :target=>'_blank')
    end
    out + "</div>"
  end
end
