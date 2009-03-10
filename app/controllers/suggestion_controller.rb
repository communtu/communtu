class SuggestionController < ApplicationController
  def title
    "Ubuntu-Linux an die individuellen Bedürfnisse anpassen"
  end
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
          metas = Metapackage.find(:all, :conditions => ["category_id = ? and default_install = ? and license_type <= ?", \
            category.id, 1, current_user.license])
        end    
        @selection.store(category, metas)
    
    end
  end

  def install_sources
    Dir.chdir RAILS_ROOT
    
    # increase version number
    if current_user.profile_version.nil? then
       current_user.profile_version = 1
       current_user.profile_changed = true
    else
      if current_user.profile_changed then
        current_user.profile_version += 1
      end  
    end

    name = BasePackage.debianize_name("communtu-add-sources-"+current_user.login)
    version = current_user.profile_version.to_s

    # if profile has changed, generate new debian metapackage
    if current_user.profile_changed then
      description = "Quellen und Schluessel hinzufuegen fuer Benutzer "+current_user.login
      debfile = Metapackage.makedeb_for_source_install(name,
                 version,
                 description,
                 current_user.selected_packages,
                 current_user.distribution, 
                 current_user.derivative, 
                 current_user.license,
                 current_user.security)
      current_user.profile_changed = false
    else
      debfile = Dir.glob("debs/#{name}/#{name}_#{version}*deb")[0]
    end
    current_user.save
    send_file debfile, :type => 'application/x-debian-package'
    # todo: what to do if debfile is nil?
  end

  def install_new
    if logged_in? then
      dist = current_user.distribution
      # package list has already been created for logged in user
      install_aux(current_user.selected_packages,dist,current_user.license,current_user.security)
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
           metas = Metapackage.find(:all, :conditions => ["category_id = ? and default_install = ?", \
                                                       category, 1])
        end                                               
        packages += metas
      end
      install_aux(packages,distribution,license,security)
    end
  end

  def quick_install
    dist = current_user.distribution
    install_aux([Metapackage.find(params[:mid])],dist,current_user.license,current_user.security)
  end

  def install
    packages = params[:post].map {|id,unused| Metapackage.find(id)}
    dist = current_user.distribution
    install_aux(packages,dist,current_user.license,current_user.security)
  end

  def install_aux(packages,dist,license,security)

    script          = "gksudo echo\n"
    script += "#!/bin/bash\n\n"
    script += "APTLIST=\"/etc/apt/sources.list\"\n\n"
    
    # generate list of packages, grouped by main bundles
    script += "PACKAGES=\"\"\n"
    sources = Set.[]
    packages.each do |p|    
        package_names   = []
        p.recursive_packages package_names, sources, dist, license, security
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
    sources.each do |repo|
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
                out += "wget " + repository.gpgkey + " | gksudo apt-key add -\n"
            end
            out += "fi\n\n"
            package_sources << out
        end
    end
      
end

