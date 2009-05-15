class MetapackagesController < ApplicationController
  
  def title
    "Bündel"
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
  end

  # POST /metapackages
  # POST /metapackages.xml
  def create
    @metapackage = Metapackage.new(params[:metapackage])
    if @metapackage.name=="Neues Bündel" or Metapackage.all.map{|m| m.debian_name}.include?(@metapackage.debian_name) then
      flash[:error] = "Dieser Bündel-Name ist bereits vergeben!"
      render :action => "new"
    elsif params[:metapackage][:description].nil? or params[:metapackage][:description].empty? then
      flash[:error] = "Die Beschreibung darf nicht leer sein"
      render :action => "new"
    else
      #todo: check that name is unique and version is present
      respond_to do |format|
        if @metapackage.save
          flash[:notice] = "Bündel gespeichert. Es dauert ein paar Minuten, bis es auch als Metapaket verfügbar ist. "
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
    # compute debian names of existing metapackages, without "communtu-" oder "communtu-private-bundle-" prefix
    metanames = (Metapackage.all-[@metapackage]).map{|m| BasePackage.debianize_name(m.name)}
    if params[:metapackage][:name]=="Neues Bündel" or metanames.include?(BasePackage.debianize_name(params[:metapackage][:name])) then
      flash[:error] += "Dieser Bündel-Name ist bereits vergeben<br>"
      error = true
    end
    if params[:metapackage][:version].nil? or params[:metapackage][:version].empty? then
      flash[:error] += "Es muss eine Version angegeben werden (z.B. 0.1)<br>"
      error = true
    end
    if !@metapackage.debianized_version.nil? \
       and !@metapackage.debianized_version.empty? \
       and Deb.version_lt(params[:metapackage][:version],@metapackage.debianized_version) then
      flash[:error] += "Bei Änderungen muss die Version größer werden<br>"
      error = true
    end
    if params[:metapackage][:description].nil? or params[:metapackage][:description].empty? then
      flash[:error] += "Die Beschreibung darf nicht leer sein<br>"
      error = true
    end  
    # correction of nil entries
    if params[:distributions].nil? then
      params[:distributions] = []
    end
    if params[:derivatives].nil? then
      params[:derivatives] = []
    end
    Metacontent.find(:first, :conditions => ["metapackage_id = ? and base_package_id = ?",@metapackage.id,p])
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
      if @metapackage.update_attributes(params[:metapackage]) and !error
        flash[:notice] = "Bündel geändert. Es dauert ein paar Minuten, bis die Änderungen im zugehörigen Metapaket verfügbar sind. "
        fork do
          system 'echo "Metapackage.find('+@metapackage.id.to_s+').debianize" | script/console production'
        end
        format.html { redirect_to :action => :show, :id => @metapackage.id }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @metapackage.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /metapackages/1
  # DELETE /metapackages/1.xml
  def destroy
    metapackage  = Metapackage.find(params[:id])    
    metapackage.destroy

    respond_to do |format|
      format.html { redirect_to(request.env['HTTP_REFERER']) }
      format.xml  { head :ok }
    end
  end
  
  def publish
    package = Metapackage.find(params[:id]);
    package.published = Metapackage.state[:published]
    package.save!
    
    redirect_to :controller => :metapackages, :action => :show
  end
  
  def unpublish
    package = Metapackage.find(params[:id]);
    package.published = Metapackage.state[:rejected]
    package.save!
    
    redirect_to :controller => :metapackages, :action => :show
  end

  def edit_packages
    @package = Metapackage.find(params[:id]);
    card_editor(@package.name,@package.base_packages,session,current_user)
  end
  
  def remove_package
    if Metacontent.delete(params[:package_id]).nil?
      flash[:error] = "Konnte Paket nicht aus Bündel entfernen."
    end
    redirect_to :controller => :metapackages, :action => :show, :id => params[:id] 
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
            meta.published = 1
            meta.save!
            redirect_to metapackage_path(meta)
        elsif action == "unpublish"
            meta.published = 0
            meta.save!
            redirect_to metapackage_path(meta)
        elsif action == "delete"
            meta.destroy
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
    
    render_string += "<option>" + num.to_s + " Bündel ausgewählt</option>\n"
    
    if owned
        render_string += "<option>---</option>"
        render_string += "<option value='0'>Löschen</option>"
        render_string += "<option value='1'>Migrieren</option>"
        if publish
            render_string += "<option value='2'>Veröffentlichen<option/>"
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
  
  def immediate_conflicts
    @conflicts = Metapackage.all.map{|m| [m,m.immediate_conflicts]}
  end
  
  def rdepends
    @metapackage = Metapackage.find(params[:id])
    @dependencies = @metapackage.structured_all_recursive_packages    
  end
end
