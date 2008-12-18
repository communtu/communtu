class SuggestionController < ApplicationController
  
  before_filter :authorize_user_subresource
  
  def show
    @profile      = current_user.user_profiles
    @root         = Category.find(1)
    @selection    = {}
    @distribution = current_user.distribution
    @profile.each do |p|

        category = Category.find(p.category_id)
        # adapt: look for metas matching with user's distribution
        if p.rating == 0 then
          metas = []
        else
          metas = Metapackage.find(:all, :conditions => ["category_id = ? and distribution_id = ? and default_install = ? and license_type <= ?", \
            category.id, current_user.distribution.id, true, current_user.license])
        end    
        @selection.store(category, metas)
    
    end
  end

  def recursive_packages meta, package_install, package_names, package_sources, dist
    meta.base_packages.each do |p|
        if p.class == Package
            rep = p.repository(dist)
            if !rep.nil? then
              package_names.push(p.name)
              package_sources.store(rep, rep.url)
            else
              package_names.push(p.name+"NOREP")              
            end
        else
            recursive_packages p, package_install, package_names, package_sources, dist
        end
    end
  end

  def install_new
    if logged_in? then
      dist = current_user.distribution
      # package list has already been created for logged in user
      install_aux(current_user.selected_packages,dist)
    else
      # for anonymous installations, we have to build the package list now
      distribution = session[:distribution]
      security = session[:security]
      license = session[:license]
      packages = []
      # adpat, s.above
      session[:profile].each do |category, value|
        if value == 0 then
          metas = []
        else
           metas = Metapackage.find(:all, :conditions => ["category_id = ? and distribution_id = ? and license_type <= ? and default_install = ?", \
                                                       category, distribution, license, true])
        end                                               
        packages += metas
      end
      install_aux(packages,distribution)
    end
  end

  def quick_install
    dist = current_user.distribution
    install_aux([Metapackage.find(params[:mid])],dist)
  end

  def install
    packages = params[:post].map {|id,unused| Metapackage.find(id)}
    dist = current_user.distribution
    install_aux(packages,dist)
  end

  def install_aux(packages,dist)


    package_install = ""
    sources         = {}
    package_sources = "" 

    script          = "gksudo echo\n"
    script += "#!/bin/bash\n\n"
    script += "APTLIST=\"/etc/apt/sources.list\"\n\n"
    
    # generate list of packages, grouped by main bundles
    script += "PACKAGES=\"\"\n"
    packages.each do |p|    
        package_names   = []
        recursive_packages p, package_install, package_names, sources, dist
        script += "# Bündel: "+p.name+"\n"
        script += "PACKAGES=$PACKAGES\""
        package_names.each do |name|
          script += name + " "
        end
    script += "\"\n\n"
    end    
    script += "\n\n"

    #  sources
    script += "SOURCES=\""
    sources.each do |repo, url|
        script += repo.url + " " + repo.subtype + "*"
    end
    script += "\"\n\n"

    # generate question ot the user
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
    
    # add sources to /etc/apt/sources.list
    script += "IFS=\"*\"\n"
    script += "for source in $SOURCES; do\n"
    script += "\tURL=$( echo $source | cut -d \" \" -f 2 )\n"
    script += "\tTYPE=$( echo $source | cut -d \" \" -f 3-6 )\n"
    script += "\tgrep -q \"$URL.*$TYPE\" $APTLIST\n\n"
    script += "\tif [ \"$?\" != \"0\" ]; then\n\t\tsudo sh -c \"echo $source >> $APTLIST\"\n"
    script += "\tfi\n"
    script += "done\n\n"

    # add gpg keys
    sources.each do |repository, url|
      if not repository.gpgkey.nil?
        if not repository.gpgkey.empty?
          script += "wget -q " + repository.gpgkey + " -O- | sudo apt-key add -\n"
        end
      end   
    end
    script += "\n"
    
    # install packages
    script += "IFS=\" \"\n"
    script += "sudo aptitude update\n"
    script += "for package in $PACKAGES; do\n"
    script += "\tsudo aptitude install -y $package\n"
    script += "done\n"
    
    respond_to do |format|
        format.text { send_data(script, :filename => "install.sh", :type => "text", :disposition => "attachment") }
    end
    
  end
  
  def install_apt_url

    dist = current_user.distribution
    
    @package_install = []
    sources          = {}
    @package_sources = ""
   
    packages = params[:post]
    packages.each do |id,unused|
    
        package = Metapackage.find(id)
        recursive_packages package, @package_install, sources, dist
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
            if not repository.gpgkey.nil? && (not repository.gpgkey.empty?)
                out += "wget " + repository.gpgkey + " | gksudo apt-key add -\n"
            end
            out += "fi\n\n"
            package_sources << out
        end
    end
      
end

