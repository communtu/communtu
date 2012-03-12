# (c) 2008-2011 by Allgemeinbildung e.V., Bremen, Germany
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


class DownloadController < ApplicationController

  before_filter :login_required, :only => [:cd_email,:sources,:prepare_install_sources,:installation,:livecd,:current_cd,
                                           :update_data,:update_ratings,:create_livecd,:bundle_to_livecd,:settings]
  before_filter :check_livecd_enabled, :only => [:create_livecd, :create_livecd_from_bundle]

  def title
    if params[:controller] == "download" and params[:action] == "selection"
      "Communtu: " + t(:model_user_profile_tabz_1)
    elsif params[:controller] == "download" and params[:action] == "settings"
      "Communtu: " + t(:model_user_profile_tabz_4)
    elsif params[:controller] == "download" and params[:action] == "livecd"
      "Communtu: " + t(:livecd)
    else
      t(:controller_profiles_0)
    end
  end  
  
  helper :download
  
  def start
    session[:path] = "installation"
  end

  def selection
    if !logged_in?
      do_anonymous_login(true)
    end
    if !params[:path].nil?
      session[:path] = params[:path]
    end  
    user = current_user
    @ratings = {}
    user.user_profiles.each do |profile|
      @ratings.store(profile.category_id, profile.rating!=0)
    end
    
    @categories = Category.category_list.map do |c|
      c[:bundles] = c[:category].metapackages.select{|m| m.is_published? or m.user_id == current_user.id }
      c
    end
    @selection = user.selected_packages
  end
  
  def settings
    if !params[:path].nil?
      session[:path] = params[:path]
    end  
    if params[:path]=='mybundle_cd' or params[:path]=='bundle_cd'
          session[:cd_bundle] = params[:id]      
    end
    @user = current_user
    if @user.derivative.nil? then @user.derivative_id = 1 end
    @distributions = @user.possible_distributions
    user_agent = request.env['HTTP_USER_AGENT']
    @dist_string = Distribution.browser_info(user_agent)+" "+
                   Architecture.browser_info(user_agent)
  end
  
  def settings_ajax
    @user = current_user
    @user.advanced = !params[:user].nil? and params[:user][:advanced]=="1"
    @user.save
    @distributions = @user.possible_distributions
    render :partial => "distribution", :locals => {:user => @user, :distributions => @distributions}
  end

  def sources
    user = current_user
    dist = user.distribution
    license = user.license
    security = user.security
    arch = user.architecture
    if session[:path] == "install_package"
      package = Package.find(session[:package])
      @sources = {}
      package.repositories_dist(dist,arch).each do |rep|
        @sources[rep] = [package]
      end
    else
      if session[:path] == "install_bundle"
        metas = [Metapackage.find(session[:bundle])]
      else
        metas = user.selected_packages
      end  
      @sources = {}
      metas.each do |p|
         p.recursive_packages_sources @sources, dist, arch, license, security
      end
    end
    @additional_sources = @sources.keys
    Repository.close_deps(@additional_sources)
    @additional_sources -= @sources.keys
  end

  def prepare_install_sources
  end

  def installation
    @metas = current_user.selected_packages
    @meta_names = @metas.uniq.map{|m| m.debian_name}.join(",")
    @sources = {}
    @metas.each do |p|
       p.recursive_packages_sources @sources, current_user.distribution, current_user.architecture, current_user.license, current_user.security
   end
   @apt_get = @sources.values.flatten.uniq.map(&:name).join(" ")
   @source_names = @sources.keys.uniq.map(&:name).join("\n")
  end

  def livecd
    @cd = Livecd.find(:first,:conditions=>{"livecds.profile_version" => current_user.profile_version,
                                           "livecd_users.user_id" => current_user.id},
                             :include => 'livecd_users')
  end

  # update the basic data of the user's software selection
  def update_data 

    # update other user data before updating profile so changes take effect
    user = current_user
    uparams = params[:user]
    user.first_login = 0
    # we cannot use update_attributes here...
    user.security = uparams[:security]
    user.license  = uparams[:license]
    user.distribution_id = uparams[:distribution_id]
    user.derivative_id = uparams[:derivative_id]
    user.architecture_id = uparams[:architecture_id]
    user.advanced = uparams[:advanced]
    user.profile_changed = true
    if user.derivative.distributions.include?(user.distribution) then
      user.save!
      user.increase_version
    render :nothing => true
    else
      flash[:error] = t(:distribution_derivative_mismatch, 
                        :derivative => user.derivative.name,
                        :distributions=> user.derivative.distributions.map{|d| d.short_name}.join(", "))
      redirect_back_or_default('/download/settings')
    end
  end
  
  def update_ratings
    user = current_user
    user.first_login = 0
    user.profile_changed = true
    user.save!
    uid = user.id
      # get the list of categories selected via checkboxes
      if params[:categories].nil? then
        cats = []
      else
        cats = params[:categories].map {|s,v| s.to_i}
      end
      # update the data for all the main categories
      main_categories = Category.find(:all, :conditions => {:parent_id => 1, :main => true})
     # Category.find(1).children.each do |child|
        main_categories.each do |child|
        # we now use 1 for selected, in the future, this can be a boolean
        if cats.include? child.id then val = 1 else val = 0 end
        user.update_rating(child,val,user.license,user.security,{:anonymous => false, :session => session},false)
    #  end
    #else # update fine grained selection
      #replace old list of packages...
      current_user.user_packages.each do |up|
        up.destroy
      end
      #... with new one from the form
      if params[:post].nil? then params[:post] = {} end
      params[:post].each do |key, value|
        if logged_in? then
          UserPackage.create(:user_id => uid, :package_id => key, :is_selected => true)
        else
          session[:profile][:key] = value
        end
      end
    end
    render :nothing => true
  end

  def create_livecd
    user = User.find(params[:id])
    name = params[:name]
    err = Livecd.check_name(name)
    if !err.nil? then
      flash[:error] = err
      redirect_to "/download/livecd"
    else
      flash[:notice] = t(:livecd_create)
      # create new live CD
      user.livecd(name,true,params[:kvm],params[:usb])
      redirect_to "/download/cd_email"
    end
  end

  def bundle_to_livecd
    if !params[:path].nil?
      session[:path] = params[:path]
    end  
    if params[:id].nil? then
      params[:id] = session[:cd_bundle] 
    end
    @bundle = Metapackage.find_by_id(params[:id])
    if @bundle.nil? then
      redirect_to session[:backlink]
      return
    end
    session[:cd_bundle] = @bundle.id
    # check if live CD has been generated already
    @cd = Livecd.find(:first,:conditions=>{:metapackage_id => @bundle.id,
                                    :distribution_id => current_user.distribution.id,
                                    :derivative_id => current_user.derivative.id,
                                    :architecture_id => current_user.architecture.id,
                                    :license_type => current_user.license,
                                    :security_type => current_user.security})
    @cd.register(current_user) unless @cd.nil?
  end

  def create_livecd_from_bundle
    if params[:id].nil? then
      params[:id] = session[:cd_bundle] 
    end
    @bundle = Metapackage.find(params[:id])
    session[:cd_bundle] = @bundle.id
    cd = current_user.bundle_to_livecd(@bundle,true,params[:kvm],params[:usb])
    if cd.nil? then
      flash[:error] = t(:livecd_failed)
    end
    redirect_to "/download/cd_email"
  end
  
  def cd_email
    @cd = current_user.current_livecd
    if !@cd.nil? and @cd.generated 
      redirect_to :action => 'current_cd'
    end
  end

  def current_cd
    @cd = current_user.current_livecd
    @back2 = !@cd.nil? and @cd.generated 
  end

  def usb
    @cd = current_user.current_livecd
    @back2 = !@cd.nil? and @cd.generated 
  end
  
  def livecd_new
  end

end
