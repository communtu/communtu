# (c) 2008-2010 by Verein Allgemeinbildung e.V., Bremen, Germany
# use, modification or distribution only with permission of the copyright holder

class PackagesController < ApplicationController
  before_filter :login_required
  before_filter :check_administrator_role, :add_flash => { :notice => I18n.t(:no_admin) }, :only => :destroy

  def title
    t(:packages)
  end
  # GET /Packages
  # GET /Packages.xml
  def index
    @packages     = Package.find_packages(session[:search], session[:group], session[:programs], session[:exact], params[:page])
    @groups       = Package.find(:all, :select => "DISTINCT section", :order => "section")
    
    respond_to do |format|
      format.html { render :action => "index.html.erb" }
      format.xml  { render :xml => @Packages }
    end
  end
  
  def bundle
    @packages = BasePackage.find(:all, :conditions => {:type => "Metapackage",:published => 1})
    @packages += BasePackage.find(:all, :conditions => {:type => "Metapackage",:user_id => current_user.id,:published => 0}) 
    respond_to do |format|
      format.html { render :action => "bundle.html.erb" }
      format.xml  { render :xml => @Packages }
    end
  end                                
  
  def search
    session[:exact] = params[:exact]
    if session[:exact].nil? then session[:exact] = false end
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

  def search_bundle
    session[:search] = params[:search]
    redirect_to "/bundle"
  end
                                                
  
  # GET /Packages/1
  # GET /Packages/1.xml
  def show
    @package = Package.find(params[:id])
    show_aux
  end  
  def show_aux  
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
        flash[:notice] = t(:controller_packages_1)
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
      if params[:video_descr][:v]!= "" then
        descr = params[:video_descr][:v]
      else
        descr = nil
      end
      if ((descr != nil) && (!params[:video_url].nil?))
    @video = Video.new(params[:video])
    @translation1 = Translation.new
    @translation2 = Translation.new
    @last_trans = Translation.find(:first, :order => "translatable_id DESC")
    last_id = @last_trans.translatable_id
    @translation1.translatable_id = last_id + 1
    @translation1.contents = descr
    @translation2.translatable_id = last_id + 2
    @translation2.contents = params[:video_url]
    if @translation1.contents != ""
      @video.description_tid = last_id + 1
      @translation1.language_code = I18n.locale.to_s
      @translation1.save
    end
       if @translation2.contents != ""
      @video.url_tid = last_id + 2
      @translation2.language_code = I18n.locale.to_s
      @translation2.save
    end
      @video.base_package_id = @package.id
      @video.save
        end
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
        flash[:notice] = t(:controller_packages_2)
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
      format.html { redirect_to(packages_url) }
      format.xml  { head :ok }
    end
  end
  
  # Ubuntu Metapaket in Bündel konvertieren
  def convert
    @package = Package.find(params[:id])
    # if the future, the editor should not only use the keys,
    # but also extract the list of distributions per package
    card_editor(@package.name,(@package.dependencies_union {|x| x.depends_or_recommends }).keys,session,current_user)
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

  def rdepends
    @package = Package.find(params[:id])
    @dependencies = @package.structured_all_recursive_packages    
  end

  def install
    session[:package] = params[:id]
    session[:path] = "install_package"
    redirect_to :action => "install_current"
  end

  def install_current
    @package  = Package.find_by_id(session[:package])
    if @package.nil?
      flash[:error] = t(:no_package_selected)
      redirect_to :action => 'index'
    end
    show_aux
  end
  
  def install_current_sources
  end
  
  def install_current_package
    @package = Package.find_by_id(session[:package])
  end
end
