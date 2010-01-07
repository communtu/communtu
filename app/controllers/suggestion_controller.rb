class SuggestionController < ApplicationController
  def title
    t(:view_layouts_application_21)
  end

  def install_sources
    if check_login then return end
    if current_user.selected_packages.empty? then
      flash[:error] = t(:controller_suggestion_1)
      redirect_to "/users/#{self.id}/user_profile/edit"
      return
    end
    debfile = current_user.install_sources
    if debfile.nil? then
      flash[:error] = t(:creation_error)
      redirect_to "/home"
      return
    end
    send_file debfile, :type => 'application/x-debian-package'
  end

  def install_bundle_sources
    if check_login then return end
    bundle = Metapackage.find(params[:mid])
    debfile = current_user.install_bundle_sources(bundle)
    if debfile.nil? then
      flash[:error] = t(:creation_error)
      redirect_to "/home"
      return
    end
    send_file debfile, :type => 'application/x-debian-package'
  end

  def install_package_sources
    if check_login then return end
    package = Package.find(params[:pid])
    debfile = current_user.install_package_sources(package)
    if debfile.nil? then
      flash[:error] = "Bei der Erstellung des Pakets ist ein Fehler aufgetreten."
      return
    end
    send_file debfile, :type => 'application/x-debian-package'
  end

  def install_bundle_as_meta
    if check_login then return end
    if current_user.selected_packages.empty? then
      flash[:error] = t(:controller_suggestion_1)
      redirect_to "/users/#{current_user.id}/user_profile/edit"
      return
    end
    debfile = current_user.install_bundle_as_meta
    if debfile.nil? then
      flash[:error] = t(:creation_error)
      redirect_to "/home"
      return
    end
    send_file debfile, :type => 'application/x-debian-package'
  end

  def bundle_to_livecd
    if check_login then return end
    bundle = Metapackage.find(params[:mid])
    current_user.bundle_to_livecd(bundle)
      redirect_to "/users/#{current_user.id}/user_profile/livecd"
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

