module ApplicationHelper

  def package_link name
    p = Package.find(:first,:conditions =>{:name => name.downcase})
    if p.nil?
      return ""
    end
   link_to name, package_url(p)
  end 
  
end
