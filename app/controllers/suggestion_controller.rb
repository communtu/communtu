class SuggestionController < ApplicationController
  def title
    t(:controller_suggestion_0)
  end
  before_filter :authorize_user_subresource
  
  def install_sources
    Dir.chdir RAILS_ROOT
    
    current_user.increase_version

    name = BasePackage.debianize_name("communtu-add-sources-"+current_user.login)
    version = current_user.profile_version.to_s

    if current_user.selected_packages.empty? then
      flash[:error] = t(:controller_suggestion_1)
      redirect_to "/users/#{current_user.id}/user_profile/tabs/0"
      return
    end

    debfile = Dir.glob("debs/#{name}/#{name}_#{version}*deb")[0]
    # if profile has changed, generate new debian metapackage
    if current_user.profile_changed or debfile.nil? then
      description = t(:controller_suggestion_2)+current_user.login
      debfile = Metapackage.makedeb_for_source_install(name,
                 version,
                 description,
                 current_user.selected_packages,
                 current_user.distribution, 
                 current_user.derivative, 
                 current_user.license,
                 current_user.security)
      current_user.profile_changed = false
    end
    current_user.save
    if debfile.nil? then
      flash[:error] = t(:controller_suggestion_3)
      redirect_to "/home"
      return
    end
    send_file debfile, :type => 'application/x-debian-package'
  end

  def install_bundle_sources
    Dir.chdir RAILS_ROOT
    bundle = Metapackage.find(params[:mid])    

    name = BasePackage.debianize_name("communtu-add-sources-#{current_user.login}-#{bundle.name}")
    version = current_user.profile_version.to_s

    description = t(:controller_suggestion_4)+bundle.name
    debfile = Metapackage.makedeb_for_source_install(name,
                 version,
                 description,
                 [bundle],
                 current_user.distribution, 
                 current_user.derivative, 
                 current_user.license,
                 current_user.security)
    if debfile.nil? then
      flash[:error] = t(:controller_suggestion_3)
      redirect_to "/home"
      return
    end
    send_file debfile, :type => 'application/x-debian-package'
  end

  def install_package_sources
    Dir.chdir RAILS_ROOT
    package = Package.find(params[:pid])    
    repos = package.repositories_dist(current_user.distribution)
    name = BasePackage.debianize_name("communtu-add-sources-#{current_user.login}-#{package.name}")
    version = "0.1"
    description = t(:controller_suggestion_6)+package.name
    # only install sources, no packages
    codename = Metapackage.codename(current_user.distribution, 
                 current_user.derivative, 
                 current_user.license,
                 current_user.security)
    debfile = Metapackage.makedeb(name,version,[],description,codename,current_user.derivative,repos)
    if debfile.nil? then
      flash[:error] = "Bei der Erstellung des Pakets ist ein Fehler aufgetreten."
      return
    end
    send_file debfile, :type => 'application/x-debian-package'
  end

  def install_bundle_as_meta
    Dir.chdir RAILS_ROOT

    current_user.increase_version
    
    name = BasePackage.debianize_name("communtu-install-"+current_user.login)
    version = current_user.profile_version.to_s

    if current_user.selected_packages.empty? then
      flash[:error] = t(:controller_suggestion_1)
      redirect_to "/users/#{current_user.id}/user_profile/tabs/0"
      return
    end

    debfile = Dir.glob("debs/#{name}/#{name}_#{version}*deb")[0]
    # if profile has changed, generate new debian metapackage
    if current_user.profile_changed or debfile.nil? then
      description = t(:controller_suggestion_8)+current_user.login
      codename = Metapackage.codename(current_user.distribution, 
                 current_user.derivative, 
                 current_user.license,
                 current_user.security)
      debfile = Metapackage.makedeb(name,
                 version,
                 current_user.selected_packages.map{|p| p.debian_name},                 
                 description,
                 codename, 
                 current_user.derivative, 
                 [])
      current_user.profile_changed = false
    end
    current_user.save
    if debfile.nil? then
      flash[:error] = t(:controller_suggestion_9)
      redirect_to "/home"
      return
    end
    send_file debfile, :type => 'application/x-debian-package'
  end

  
###########################################################################
# installation via shell script
###########################################################################
  def install_new
    dist = current_user.distribution
    install_aux(current_user.selected_packages,dist,current_user.license,current_user.security,current_user.derivative)
  end

  def quick_install
    dist = current_user.distribution
    install_aux([Metapackage.find(params[:mid])],dist,current_user.license,current_user.security,current_user.derivative)
  end

  def install
    packages = params[:post].map {|id,unused| Metapackage.find(id)}
    dist = current_user.distribution
    install_aux(packages,dist,current_user.license,current_user.security,current_user.derivative)
  end

  def install_aux(packages,dist,license,security,derivative)
    sudo = derivative.sudo
    dialog = derivative.dialog
    script          = "#{sudo} echo\n"
    script += "#!/bin/bash\n\n"
    script += "APTLIST=\"/etc/apt/sources.list\"\n"
    script += "APTPIN=\"/etc/apt/preferences\"\n\n"
    
    # generate list of packages, grouped by main bundles
    script += "PACKAGES=\"\"\n"
    sources = Set.[]
    packages.each do |p|    
        package_names   = []
        p.recursive_packages package_names, sources, dist, license, security
        script += "# "+t(:controller_suggestion_10)+": "+p.name+"\n"
        script += "PACKAGES=$PACKAGES\""
        package_names.each do |name|
          script += name + " "
        end
    script += "\"\n\n"
    end    
    script += "\n\n"

    #  sources
    sources_line = ""
    sources.each do |repo|
        sources_line += repo.url + " " + repo.subtype + "*"
    end
    script += "SOURCES=\"#{sources_line}\"\n\n"

    # generate question ot the user
    if dialog == "zenity" then
      script += "IFS=\"*\"\n"
      script += "#{dialog} --list --width 500 --height 300 --title \""+ t(:controller_suggestion_11) + "\" " + 
          "--text \""+ t(:controller_suggestion_12)+"\" --column \"Quelle\" $SOURCES\n"
    elsif dialog == "kdialog" then
      sources_lined = sources_line.gsub("*","\\n")
      script += "SOURCESD=\"#{sources_lined}\"\n\n"
      script += "#{dialog} --geometry 500x300 --title \""+ t(:controller_suggestion_11) + "\"" + 
          "--yesno \"" + t(:controller_suggestion_12) + "\\n$SOURCESD\"\n"
    end  
    script += "\n"

    script += "if [ $? != 0 ]; then\n\texit 0\nfi\n\n"
    
    if dialog == "zenity" then
      script += "IFS=\" \"\n"
      script += "#{dialog} --list --width 500 --height 300 --title \""+ t(:controller_suggestion_15) + "\" " +
          "--text \"" + t(:controller_suggestion_16) + "\" --column \"Paket\" $PACKAGES \n"
    elsif dialog == "kdialog" then
      script += "#{dialog} --geometry 500x300 --title \"" + t(:controller_suggestion_15) + "\" " + 
          "--yesno \"" + t(:controller_suggestion_16) + "\\n$PACKAGES\"\n"
    end          
    script += "\n"
    
    script += "if [ $? != 0 ]; then\n\texit 0\nfi\n\n"
    
    # add sources to /etc/apt/sources.list
    script += "IFS=\"*\"\n"
    script += "for source in $SOURCES; do\n"
    script += "\tURL=$( echo $source | cut -d \" \" -f 2 )\n"
    script += "\tDISTRIBUTION=$( echo $source | cut -d \" \" -f 3 )\n"
    script += "\tCOMPONENT=$( echo $source | cut -d \" \" -f 4-6 )\n"
    script += "\tegrep -q \"^[^#]*$URL.*$DISTRIBUTION([a-zA-Z-]* )*$COMPONENT($| )\" $APTLIST\n\n"
    script += "\tif [ \"$?\" != \"0\" ]; then\n\t\tsudo sh -c \"echo $source >> $APTLIST\"\n"
#    script += "\t\tsudo sh -c \"echo >> $APTPIN\"\n"
#    script += "\t\tsudo sh -c \"echo \\\"Package: *\\\" >> $APTPIN\"\n"
#    script += "\t\tsudo sh -c \"echo \\\"Pin: $source\\\" >> $APTPIN\"\n"
#    script += "\t\tsudo sh -c \"echo \\\"Pin-Priority: 100\\\" >> $APTPIN\"\n"
    script += "\tfi\n"
    script += "done\n\n"

    # add gpg keys
    sources.each do |repository|
      if not repository.gpgkey.nil?
        if not repository.gpgkey.empty?
          script += "wget -q " + repository.gpgkey + " -O- | sudo apt-key add -\n"
        end
      end   
    end
    script += "\n"
    
    # install packages
    script += "IFS=\" \"\n"
    script += "#{sudo} apt-get update\n"
    script += "for package in $PACKAGES; do\n"
    script += "\tsudo apt-get install -y $package\n" # here normal sudo due to -y option
    script += "done\n"
    
    respond_to do |format|
        format.text { send_data(script, :filename => "install.sh", :type => "text", :disposition => "attachment") }
    end
    
  end
  
  def install_apt_url

    dist = current_user.distribution
    
    sources          = Set.[]
    @package_sources = ""
   
    packages = params[:post]
    packages.each do |id,unused|
    
        package = Metapackage.find(id)
        package.recursive_packages sources, dist
    end
    
    gen_package_sources sources, @package_sources
    
  end
  
  private
  
    def gen_package_sources sources, package_sources
        sources.each do |repository|
            out  = "SOURCE=\"" + repository.url + " " + repository.subtype + "\"\n"
            out += "grep -q \"" + repository.url + ".*" + repository.subtype + "\" $APTLIST\n\n"
            out += "if [ \"$?\" != \"0\" ]; then\n" +
                "\tsudo sh -c \"echo $SOURCE >> $APTLIST\"\n"
            if not repository.gpgkey.nil? && (not repository.gpgkey.empty?)
                out += "wget " + repository.gpgkey + " | #{sudo} apt-key add -\n"
            end
            out += "fi\n\n"
            package_sources << out
        end
    end
      
end

