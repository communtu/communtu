class PackagesController < ApplicationController
  
  # GET /Packages
  # GET /Packages.xml
  def index         
    @distribution = Distribution.find(params[:distribution_id])
    @packages     = Package.find_packages(session[:search], session[:group], session[:programs], params[:page], @distribution)
    @groups       = Package.find(:all, :select => "DISTINCT section", :order => "section")
    
    respond_to do |format|
      format.html { render :action => "index.html.erb" }
      format.xml  { render :xml => @Packages }
    end
  end
  
  def search
    session[:search] = params[:search]
    session[:programs] = params[:programs]
    if session[:programs].nil? then session[:programs] = false end
    group = params[:group]
    if group.nil? or group == "all"
      session[:group] = "all"
    else
      session[:group] = group
    end
    redirect_to distribution_path(Distribution.find(params[:id])) + "/packages"
  end
  
  # GET /Packages/1
  # GET /Packages/1.xml
  def show
    @package = Package.find(params[:id])
    
    if not session[:meta_cart].nil?
      dist = TempMetapackage.find(:first, :conditions => [ "id=?", session[:meta_cart] ])
    end
    
    if not dist.nil?
      @distribution_id = dist.distribution_id
    else
      @distribution_id = -1 if @distribution_id.nil?
    end
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @package }
    end
  end

  # GET /Packages/new
  # GET /Packages/new.xml
  def new
    @package = Package.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @package }
    end
  end

  # GET /Packages/1/edit
  def edit
    @package = Package.find(params[:id])
  end

  # POST /Packages
  # POST /Packages.xml
  def create
    @package = Package.new(params[:Package])

    respond_to do |format|
      if @package.save
        flash[:notice] = 'Paket erzeugt.'
        format.html { redirect_to(@Package) }
        format.xml  { render :xml => @package, :status => :created, :location => @package }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @package.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /Packages/1
  # PUT /Packages/1.xml
  def update
    @package = Package.find(params[:id])
    if !params[:package][:icon_file].nil? && (params[:package][:icon_file].size > 0) then
       # file name without full path
       icon_file = params[:package][:icon_file].original_filename.split("/")[-1]
       complete_path = RAILS_ROOT + '/public/images/apps/' + icon_file
       # avoid duplicate file names
       while FileTest.file?(complete_path + '/' + icon_file)
         icon_file = "x"+icon_file
       end
       # save image file
       begin
         f = File.open(complete_path + '/' + icon_file, 'wb')
         # upload file to web server
         f.write(params[:package][:icon_file].read)
         params[:package][:icon_file] = icon_file
       rescue
          # failed to sav? then ignore it
          params[:package].delete(:icon_file)
       ensure
         f.close unless f.nil?
       end  
    end   
    respond_to do |format|
      if @package.update_attributes(params[:package])
        flash[:notice] = 'Paket aktualisiert.'
        format.html { redirect_to :action => 'show', :id => @package.id }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @package.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /Packages/1
  # DELETE /Packages/1.xml
  def destroy
    @package = Package.find(params[:id])
    @package.destroy

    respond_to do |format|
      format.html { redirect_to(Packages_url) }
      format.xml  { head :ok }
    end
  end
  
  # Ubuntu Metapaket in Bündel konvertieren
  def convert
    @package = Package.find(params[:id])
    card_editor(@package.name,@package.depends_or_recommends,session,current_user)
  end
end
