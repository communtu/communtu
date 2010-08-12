# (c) 2008-2010 by Verein Allgemeinbildung e.V., Bremen, Germany
# use, modification or distribution only with permission of the copyright holder

module RepositoriesHelper
  def select_license_type repos  = nil
    
    if repos.nil?
      repos = Repository.new
      repos.license_type = 0
    end
    selected = Array.new Package.license_types.length, ""
    selected[repos.license_type] = " selected='selected'"
    
    select_tag "repository[license_type]", get_select_options(Package.license_types, selected)
  end
  
  def select_security_type repos = nil
    
    if repos.nil?
      repos = Repository.new
      repos.security_type = 0
    end
    selected = Array.new Package.security_types.length, ""
    selected[repos.security_type] = " selected='selected'"
    
    select_tag "repository[security_type]", get_select_options(Package.security_types, selected)
  end
  
  def get_select_options types, selected
    options = ""
    
    types.length.times do |i|
      
      options += "<option value='#{i}'" + selected[i] + ">" + types[i] + "</option>"
    end
    options
  end
  
  def select_distribution repos, distributions
    
    selected = " selected='selected'"
    options = ""
    
    distributions.each do |dist|
      
      options += "<option"
      options += " selected='selected'" if dist.id == repos.distribution_id
      options << " value='" << dist.id.to_s << "'>" << dist.name << "</option>" 
    end
    
    select_tag "repository[distribution_id]", options
  end
  
end
