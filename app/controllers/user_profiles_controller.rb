
class UserProfilesController < ApplicationController
  def title
    t(:controller_profiles_0)
  end  
  
  helper :user_profiles  
    
  def edit
    if check_login then return end
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
    if check_login then return end
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
    @distributions = @user.possible_distributions
    render :partial => "distribution", :locals => {:user => @user, :distributions => @distributions}
  end

  def sources
    if check_login then return end
    user = current_user
    metas = user.selected_packages
    dist = user.distribution
    license = user.license
    security = user.security
    arch = user.architecture
    @sources = {}
    metas.each do |p|
       p.recursive_packages_sources @sources, dist, arch, license, security
    end
    @additional_sources = @sources.keys
    Repository.close_deps(@additional_sources)
    @additional_sources -= @sources.keys
  end

  def installation
    if check_login then return end
    @metas = current_user.selected_packages.uniq.map{|m| m.debian_name}.join(",")
  end

  def livecd
    if check_login then return end
    @cd = Livecd.find(:first,:conditions=>{"livecds.profile_version" => current_user.profile_version,
                                           "livecd_users.user_id" => current_user.id},
                             :include => 'livecd_users')
  end

  # update the basic data of the user's software selection
  def update_data 
    if check_login then return end

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
      redirect_to user_user_profile_path(current_user) + "/installation"
    else
      flash[:error] = t(:distribution_derivative_mismatch, 
                        :derivative => user.derivative.name,
                        :distributions=> user.derivative.distributions.map{|d| d.short_name}.join(", "))
      redirect_back_or_default('/user_profiles/settings')
    end
  end
  
  def update_ratings
    if check_login then return end
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
    # redirect_to user_user_profile_path(current_user) + "/installation"
  end

  def create_livecd
    user = User.find(params[:id])
    name = params[:name]
    err = Livecd.check_name(name)
    if !err.nil? then
      flash[:error] = err
      redirect_to user_user_profile_path(current_user) + "/livecd"
    else
      flash[:notice] = t(:livecd_create)
      # create new live CD
      user.livecd(name,true,params[:kvm],params[:usb])
      redirect_to "/livecds"
    end
  end

  def bundle_to_livecd
    if check_login then return end
    @bundle = Metapackage.find(params[:id])
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
    @bundle = Metapackage.find(params[:id])
    current_user.bundle_to_livecd(@bundle,true,params[:kvm],params[:usb])
    redirect_to "/livecds"
  end
end
