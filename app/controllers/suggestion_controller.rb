class SuggestionController < ApplicationController
  def title
    t(:view_layouts_application_21)
  end

  def install_sources
    if check_login then return end
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
      debfile = Deb.makedeb_for_source_install(name,
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
      flash[:error] = t(:creation_error)
      redirect_to "/home"
      return
    end
    send_file debfile, :type => 'application/x-debian-package'
  end

  def install_bundle_sources
    if check_login then return end
    Dir.chdir RAILS_ROOT
    bundle = Metapackage.find(params[:mid])    

    name = BasePackage.debianize_name("communtu-add-sources-#{current_user.login}-#{bundle.name}")
    version = current_user.profile_version.to_s

    description = t(:controller_suggestion_4)+bundle.name
    debfile = Deb.makedeb_for_source_install(name,
                 version,
                 description,
                 [bundle],
                 current_user.distribution, 
                 current_user.derivative, 
                 current_user.license,
                 current_user.security)
    if debfile.nil? then
      flash[:error] = t(:creation_error)
      redirect_to "/home"
      return
    end
    send_file debfile, :type => 'application/x-debian-package'
  end

  def install_package_sources
    if check_login then return end
    Dir.chdir RAILS_ROOT
    package = Package.find(params[:pid])    
    repos = package.repositories_dist(current_user.distribution,current_user.architecture)
    name = BasePackage.debianize_name("communtu-add-sources-#{current_user.login}-#{package.name}")
    version = "0.1"
    description = t(:controller_suggestion_6)+package.name
    # only install sources, no packages
    codename = Deb.compute_codename(current_user.distribution,
                 current_user.derivative, 
                 current_user.license,
                 current_user.security)
    debfile = Deb.makedeb(name,version,[],description,codename,current_user.derivative,repos)
    if debfile.nil? then
      flash[:error] = "Bei der Erstellung des Pakets ist ein Fehler aufgetreten."
      return
    end
    send_file debfile, :type => 'application/x-debian-package'
  end

  def install_bundle_as_meta
    if check_login then return end
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
      codename = Deb.compute_codename(current_user.distribution,
                 current_user.derivative, 
                 current_user.license,
                 current_user.security)
      debfile = Deb.makedeb(name,
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
      flash[:error] = t(:creation_error)
      redirect_to "/home"
      return
    end
    send_file debfile, :type => 'application/x-debian-package'
  end

 
  
  def install_apt_url
    if check_login then return end

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
                out += "#{sudo} #{Deb::APT_KEY_COMMAND} #{Deb::KEYSERVER} #{repository.gpgkey} \n"
            end
            out += "fi\n\n"
            package_sources << out
        end
    end
      
end

