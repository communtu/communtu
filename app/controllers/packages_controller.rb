class PackagesController < ApplicationController

  def title
    "Pakete"
  end
  # GET /Packages
  # GET /Packages.xml
  def index         
    @packages     = Package.find_packages(session[:search], session[:group], session[:programs], params[:page])
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
    redirect_to "/packages"
  end
  
  # GET /Packages/1
  # GET /Packages/1.xml
  def show
    @package = Package.find(params[:id])
    
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
    # enter new video
    if !params[:video_url].nil? then
      if !params[:video_descr].nil? then
         descr = params[:video_descr][:v]
      else 
        descr = nil
      end  
      Video.create(:base_package_id => @package.id, :url => params[:video_url], :description => descr)
    end
    # enter new icn file
    if !params[:package][:icon_file].nil? && (params[:package][:icon_file].size > 1) then
       # file name without full path
       icon_file = params[:package][:icon_file].original_filename.split("/")[-1]
       path = RAILS_ROOT + '/public/images/apps/'
       # avoid duplicate file names
       while FileTest.file?(path + icon_file)
         icon_file = "x"+icon_file
       end
       # save image file
       begin
         f = File.open(path + icon_file, 'wb')
         # upload file to web server
         f.write(params[:package][:icon_file].read)
         params[:package][:icon_file] = icon_file
       rescue
          # failed to sav? then ignore it
          params[:package].delete(:icon_file)
       ensure
         f.close unless f.nil?
       end  
    else
      params[:package][:icon_file] = @package.icon_file
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
    # if the future, the editor should not only use the keys,
    # but also extract the list of distributions per package
    card_editor(@package.name,@package.dependencies_union.keys,session,current_user)
  end
  
  def add_comment
    @id = params[:id]
  end
  
  def save_comment
    c = Comment.new({ :metapackage_id => params[:id],\
      :user_id => current_user.id,\
      :comment => params[:comment] } )
    c.save 
    redirect_to :controller => :packages, :action => :show, :id => params[:id] 
  end


end
