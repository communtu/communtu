class SuggestionController < ApplicationController
  
  before_filter :authorize_user_subresource
  
  def show
    @profile   = current_user.user_profiles
    @root      = Category.find(1)
    @selection = {}
    @profile.each do |p|

        category = Category.find(p.category_id)
        metas    = Metapackage.find(:all, :conditions => ["category_id = ? and rating <= ? and license_type <= ?", category.id, p.rating, current_user.license])
        @selection.store(category, metas)
    
    end
  end 

  def install

    script          = ""
    package_install = ""
    package_sources = ""
   
    script += "#!/bin/bash\n\n"
    script += "file=\"/etc/apt/sources.list\"\n\n"
   
    packages = params[:post]
    packages.each do |id,unused|
        package = Metapackage.find(id)
        package.packages.each do |p|
            package_install += (p.name + " ")
            package_sources += gen_package_source p
        end
    end
    
    script += package_sources
    script += "apt-get update\n"
    script += "apt-get install " + package_install + "\n"
    
    respond_to do |format|
        format.text { send_data(script, :filename => "install.sh", :type => "text", :disposition => "attachment") }
    end
    
  end
  
  private
  
    def gen_package_source package
        out  = "source=\"" + package.repository.url + " " + package.repository.subtype + "\"\n"
        out += "grep -q \"package.repository.url" + ".*" + package.repository.subtype + "\" $file\n\n"
        out += "if [ \"$?\" != \"0\" ]; then\n" +
        "\techo \"$source\" >> $file\n" +
        "fi\n\n"
    end
      
end

