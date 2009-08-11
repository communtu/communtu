class MetapackagesController < ApplicationController
  before_filter :login_required
  before_filter :is_anonymous, :only => :publish

  def title
    t(:bundle)
  end

  @@migrations = {}
    
  # GET /metapackages
  # GET /metapackages.xml
  def index
    @metapackages = Metapackage.find(:all)
  
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @metapackages }
    end
  end

  # GET /metapackages/1
  # GET /metapackages/1.xml
  def show
    @metapackage = Metapackage.find(params[:id])
    @conflicts = @metapackage.internal_conflicts
    if logged_in?
    @distribution = current_user.distribution
    @derivative = current_user.derivative
    end
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @metapackage }
    end
  end

  # GET /metapackages/new
  # GET /metapackages/new.xml
  def new
    @metapackage = Metapackage.new
    @backlink    = request.env['HTTP_REFERER']

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @metapackage }
    end
  end

  # GET /metapackages/1/edit
  def edit
    @metapackage = Metapackage.find(params[:id])
    @categories  = Category.find(1)
    @backlink    = request.env['HTTP_REFERER']
    @conflicts   = {}
  end

  # POST /metapackages
  # POST /metapackages.xml
  def create
    @metapackage = Metapackage.new(params[:metapackage])
    @metapackage.modified = true
    if @metapackage.name==t(:new_bundle) or Metapackage.all.map{|m| m.debian_name}.include?(@metapackage.debian_name) then
      flash[:error] = t(:controller_metapackages_2)
      render :action => "new"
    elsif params[:metapackage][:description].nil? or params[:metapackage][:description].empty? then
      flash[:error] = t(:controller_metapackages_3)
      render :action => "new"
    else
      #todo: check that name is unique and version is present
      respond_to do |format|
        if @metapackage.save
          flash[:notice] = t(:controller_metapackages_4)
          fork do
            system 'echo "Metapackage.find('+@metapackage.id.to_s+').debianize" | script/console production'
          end
          format.html { redirect_to(@metapackage) }
          format.xml  { render :xml => @metapackage, :status => :created, :location => @metapackage }
        else
          format.html { render :action => "new" }
          format.xml  { render :xml => @metapackage.errors, :status => :unprocessable_entity }
        end  
      end
    end
  end

  # PUT /metapackages/1
  # PUT /metapackages/1.xml
  def update 
    error = false
    flash[:error] = ""
    @metapackage = Metapackage.find(params[:id])
    @conflicts = @metapackage.internal_conflicts
    if !@conflicts.empty? then
        flash[:error] += t(:controller_metapackages_conflicts)
        error = true
    end
    if @metapackage.is_published? then
      if !params[:metapackage][:name].nil? and params[:metapackage][:name]!=@metapackage.name then
        flash[:error] += t(:controller_metapackages_no_renaming)
        error = true
      end
    else
      # compute debian names of existing metapackages, without "communtu-" oder "communtu-private-bundle-" prefix
      metanames = (Metapackage.all-[@metapackage]).map{|m| BasePackage.debianize_name(m.name)}
      if params[:metapackage][:name]==t(:new_bundle) or metanames.include?(BasePackage.debianize_name(params[:metapackage][:name])) then
        flash[:error] += t(:controller_metapackages_6)
        error = true
      end
    end
    if params[:metapackage][:version].nil? or params[:metapackage][:version].empty? then
      flash[:error] += t(:controller_metapackages_7)
      error = true
    end
    if !@metapackage.debianized_version.nil? \
       and !@metapackage.debianized_version.empty? \
       and !Deb.version_gt(params[:metapackage][:version],@metapackage.debianized_version) then
      flash[:error] += t(:controller_metapackages_8)
      error = true
    end
    if params[:metapackage][:description].nil? or params[:metapackage][:description].empty? then
      flash[:error] += t(:controller_metapackages_9)
      error = true
    end  
    # correction of nil entries
    if params[:distributions].nil? then
      params[:distributions] = []
    end
    if params[:derivatives].nil? then
      params[:derivatives] = []
    end
    # mark bundle as modified
    @metapackage.modified = true
    @metapackage.save
    # save selection of distributions and deriviatives
    params[:distributions].each do |p, dists|
      mc = Metacontent.find(:first, :conditions => ["metapackage_id = ? and base_package_id = ?",@metapackage.id,p])
      mc.metacontents_distrs.each {|d| d.destroy} # delete all distributions
      dists.each {|d| mc.distributions << Distribution.find(d)}     # and add the selected ones
    end
    params[:derivatives].each do |p, ders|
      mc = Metacontent.find(:first, :conditions => ["metapackage_id = ? and base_package_id = ?",@metapackage.id,p])
      mc.metacontents_derivatives.each {|d| d.destroy} # delete all derivatives
      ders.each {|d| mc.derivatives << Derivative.find(d)}             # and add the selected ones
    end
    respond_to do |format|
      # save other attributes
      if @metapackage.update_attributes(params[:metapackage]) and !error
        flash.delete(:error)
        format.html { redirect_to :action => :show, :id => @metapackage.id }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @metapackage.errors, :status => :unprocessable_entity }
      end
    end
  end

  def save
    @metapackage = Metapackage.find(params[:id])
    if !@metapackage.internal_conflicts.empty?
      flash[:error] = t(:controller_metapackages_no_save)
    elsif !@metapackage.modified
      flash[:notice] = t(:controller_metapackages_not_changed)
    elsif @metapackage.debianizing
      flash[:notice] = t(:controller_metapackages_debianizing)
    else
      @metapackage.debianize
      fork do
        system 'echo "Metapackage.find('+@metapackage.id.to_s+').generate_debs" | script/console production'
      end
    end
    redirect_to :action => :show, :id => @metapackage.id
  end
  # DELETE /metapackages/1
  # DELETE /metapackages/1.xml
  def destroy
    metapackage  = Metapackage.find(params[:id])   
    if metapackage.is_published? then
      flash[:error] = t(:controller_metapackages_cannot_destroy)
      return  
    end
    metapackage.destroy

    respond_to do |format|
      format.html { redirect_to (user_path(current_user) + "/metapackages/0") }
      format.xml  { head :ok }
    end
  end
  
  def publish
    package = Metapackage.find(params[:id]);
    package.published = Metapackage.state[:published]
    package.modified = true
    package.save!
    
    redirect_to :controller => :metapackages, :action => :show
  end
  
  def edit_packages
    @package = Metapackage.find(params[:id]);
    card_editor(@package.name,@package.base_packages,session,current_user)
  end
  
  def remove_package
    if Metacontent.delete(params[:package_id]).nil?
      flash[:error] = t(:controller_metapackages_11)
    end
    redirect_to :controller => :metapackages, :action => :edit, :id => params[:id]
  end
  
  def edit_action
    action = params[:method]
    meta   = Metapackage.find(params[:id])
    if not meta.nil?
        if action == "edit"
            redirect_to metapackage_path(meta) + "/edit"
        elsif action == "pedit"
            edit_packages
        elsif action == "publish"
          if current_user.anonymous? then
            flash[:error] = t(:controller_application_0)
            redirect_to root_path
          else
            meta.published = 1
            meta.modified = true
            meta.save!
            redirect_to metapackage_path(meta)
          end
        elsif action == "delete"
            if !meta.published
              meta.destroy
            end
            redirect_to metapackages_path
        else    
            redirect_to metapackage_path(meta)
        end
    end
  end
  
  def action
    action   = params[:method]
    packages = params[:packages]

    if action == "0"
        packages.each do |key,value|
            if value[:select] == "1"
                Metapackage.destroy(key)
            end
        end
        
        redirect_to request.env['HTTP_REFERER']
                    
    elsif action == "1"

        session[:packages] = packages
        session[:backlink] = request.env['HTTP_REFERER']
        redirect_to "/metapackage/migrate"
        
    elsif action == "2"
        
        packages.each do |key,value|
            if value[:select] == "1"
                meta = Metapackage.find(key)
                if not meta.nil?
                    meta.published = 1
                    meta.save!
                end
            end
        end
        
        redirect_to request.env['HTTP_REFERER']
    end    
    
  end
  
  def migrate
    @distributions = Distribution.find(:all)
  end
  
  def finish_migrate
    @from_dist       = Distribution.find(params[:from_dist][:id])
    @to_dist         = Distribution.find(params[:to_dist][:id])
    @backlink        = session[:backlink]
    
    metas = session[:packages]
    @not_found = {}
    if not metas.nil?
        metas.each do |key,value|
            if value[:select] == "1"
                meta = Metapackage.find(key)
                if not meta.nil?
                    @not_found[meta] = meta.migrate(@from_dist,@to_dist)
                end
            end
        end
    end
  end
  
  def changed
    
    render_string = ""
    owned         = true
    publish       = true
    num           = 0
        
    packages = params[:packages]
    packages.each do |key, value|
    
        package = Metapackage.find(key)
        if value[:select] == "1"
            
            if not is_admin? and package.user != current_user
                owned = false
            end
            
            if package.is_published?
                publish = false
            end
            
            num += 1
        
        end
   
    end
    
    render_string += "<option>" + num.to_s + t(:controller_metapackages_12)
    
    if owned
        render_string += "<option>---</option>"
        render_string += t(:controller_metapackages_13)
        render_string += t(:controller_metapackages_14)
        if publish
            render_string += t(:controller_metapackages_15)
        end
    end
    
    render :text => render_string
    
  end
  
  def add_comment
    @id = params[:id]
  end
  
  def save_comment
    c = Comment.new({ :metapackage_id => params[:id],\
      :user_id => current_user.id,\
      :comment => params[:comment] } )
    c.save 
    redirect_to :controller => :metapackages, :action => :show, :id => params[:id] 
  end
  
  def rdepends
    @metapackage = Metapackage.find(params[:id])
    @dependencies = @metapackage.structured_all_recursive_packages    
  end

  def reset
    @metapackage = Metapackage.find(params[:id])
    @metapackage.debianizing = false
    @metapackage.deb_error = false
    @metapackage.modified = true
    @metapackage.save
    Deb.find(:all,:conditions => ["metapackage_id = ? and generated = ?",@metapackage.id,false]).each do |d|
      d.generated = true
      d.save
    end
    flash[:notice] = t(:controller_metapackages_please_regenerate)
    redirect_to :action => :show, :id => params[:id]
  end
end
