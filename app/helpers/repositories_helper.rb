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
