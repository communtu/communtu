class SuggestionController < ApplicationController
  
  before_filter :authorize_user_subresource
  
  def show
    @profile   = current_user.user_profiles
    @root      = Category.find(1)
    @selection = {}
    @profile.each do |p|

        category = Category.find(p.category_id)
        metas    = Metapackage.find(:all, :conditions => ["category_id = ? and distribution_id = ? and rating <= ? and license_type <= ?", \
            category.id, current_user.distribution.id, p.rating, current_user.license])
            
        @selection.store(category, metas)
    
    end
  end

  def recursive_packages meta, package_install, package_names, package_sources
    meta.base_packages.each do |p|
        if p.class == Package
            package_names.push(p.name)
            package_sources.store(p.repository, p.repository.url)
        else
            recursive_packages p, package_install, package_names, package_sources
        end
    end
  end

  def install

    script          = "gksudo echo\n"
    package_names   = []
    package_install = ""
    sources         = {}
    package_sources = ""
   
    script += "#!/bin/bash\n\n"
    script += "APTLIST=\"/etc/apt/sources.list\"\n\n"
        
    packages = params[:post]
    packages.each do |id,unused|
    
        package = Metapackage.find(id)
        recursive_packages package, package_install, package_names, sources
    end
    
    script += "SOURCES=\""
    sources.each do |repo, url|
        script += repo.url + " " + repo.subtype + "*"
    end
    script += "\"\n\n"
    
    script += "PACKAGES=\""
    package_names.each do |name|
        script += name + " "
    end
    script += "\"\n\n"
    
    gen_package_sources sources, package_sources
    
    script += "IFS=\"*\"\n"
    script += "zenity --list --width 500 --height 300 --title \"Paketquellen hinzufügen\" " + 
        "--text \"Folgende Paketquellen werden hinzugefügt\" --column \"Quelle\" $SOURCES\n"
    script += "\n"

    script += "if [ $? != 0 ]; then\n\texit 0\nfi\n\n"
    
    script += "IFS=\" \"\n"
    script += "zenity --list --width 500 --height 300 --title \"Pakete installieren\" " +
        "--text \"Folgende Pakete werden installiert\" --column \"Paket\" $PACKAGES \n"
    script += "\n"
    
    script += "if [ $? != 0 ]; then\n\texit 0\nfi\n\n"
    
    script += "IFS=\"*\"\n"
    script += "for source in $SOURCES; do\n"
    script += "\tURL=$( echo $source | cut -d \" \" -f 2 )\n"
    script += "\tTYPE=$( echo $source | cut -d \" \" -f 3-6 )\n"
    script += "\tgrep -q \"$URL.*$TYPE\" $APTLIST\n\n"
    script += "\tif [ \"$?\" != \"0\" ]; then\n\t\tsudo sh -c \"echo $source >> $APTLIST\"\n"
    script += "\tfi\n"
    script += "done\n\n"
    
    script += "IFS=\" \"\n"
    script += "sudo apt-get update\n"
    script += "for package in $PACKAGES; do\n"
    script += "\tsudo apt-get install -y --force-yes $package\n"
    script += "done\n"
    
    respond_to do |format|
        format.text { send_data(script, :filename => "install.sh", :type => "text", :disposition => "attachment") }
    end
    
  end
  
  def install_apt_url

    @package_install = []
    sources          = {}
    @package_sources = ""
   
    packages = params[:post]
    packages.each do |id,unused|
    
        package = Metapackage.find(id)
        recursive_packages package, @package_install, sources
    end
    
    gen_package_sources sources, @package_sources
    
  end
  
  private
  
    def gen_package_sources sources, package_sources
        sources.each do |repository, url|
            out  = "SOURCE=\"" + url + " " + repository.subtype + "\"\n"
            out += "grep -q \"" + repository.url + ".*" + repository.subtype + "\" $APTLIST\n\n"
            out += "if [ \"$?\" != \"0\" ]; then\n" +
                "\tsudo sh -c \"echo $SOURCE >> $APTLIST\"\n"
            if not repository.gpgkey.nil?
                out += "\twget " + repository.gpgkey + " | gksudo apt-key add -"
            end
            out += "fi\n\n"
            package_sources << out
        end
    end
      
end

