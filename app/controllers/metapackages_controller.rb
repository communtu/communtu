class MetapackagesController < ApplicationController
  
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

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @metapackage }
    end
  end

  # GET /metapackages/new
  # GET /metapackages/new.xml
  def new
    @metapackage = Metapackage.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @metapackage }
    end
  end

  # GET /metapackages/1/edit
  def edit
    @metapackage = Metapackage.find(params[:id])
    @categories  = Category.find(1)
  end

  # POST /metapackages
  # POST /metapackages.xml
  def create
    @metapackage = Metapackage.new(params[:metapackage])

    respond_to do |format|
      if @metapackage.save
        format.html { redirect_to(@metapackage) }
        format.xml  { render :xml => @metapackage, :status => :created, :location => @metapackage }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @metapackage.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /metapackages/1
  # PUT /metapackages/1.xml
  def update
    @metapackage = Metapackage.find(params[:id])
    
    respond_to do |format|
      if @metapackage.update_attributes(params[:metapackage])
        format.html { redirect_to :action => :show, :id => @metapackage.id, :distribution_id => @metapackage.distribution.id }
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
    package = Metapackage.find(params[:id]);
    cart = Cart.new
    cart.name = package.name
    cart.save
    package.base_packages.each do |p|
      cart.base_packages << p
    end
    cart.save

    session[:cart] = cart.id
    redirect_to "/users/" + current_user.id.to_s + "/metapackages/2"    
  end
  
  def remove_package
    if Metacontent.delete(params[:package_id]).nil?
      flash[:error] = "Konnte Paket nicht aus Bündel entfernen."
    end
    redirect_to :controller => :metapackages, :action => :show, :id => params[:id] 
  end
  
  def action
    action   = params[:method]
    packages = params[:packages]

    if action == "0"
        packages.each do |key,value|
            if value[:select] == "1"
                Metapackage.delete(key)
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
    @failed_packages = []
    @double_packages = []
    @distribution    = Distribution.find(params[:distribution])
    @backlink        = session[:backlink]
    
    packages = session[:packages]
    if not packages.nil?
        packages.each do |key,value|
            if value[:select] = "1"
                package = Metapackage.find(key)
                if not package.nil?
                    package.migrate(@distribution, current_user, @failed_packages, @double_packages)
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
    @files = TempMetapackage.find(:all, :conditions => ["user_id=? AND is_saved=?",\
      current_user.id, 1])
    @id = params[:id]
  end
  
  def save_comment
    c = Comment.new({ :metapackage_id => params[:id],\
      :temp_metapackage_id => params[:attach], :user_id => current_user.id,\
      :comment => params[:comment] } )
    c.save 
    redirect_to :controller => :metapackages, :action => :show, :id => params[:id] 
  end
end
