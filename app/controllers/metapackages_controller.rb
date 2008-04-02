class MetapackagesController < ApplicationController
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
  end

  # POST /metapackages
  # POST /metapackages.xml
  def create
    @metapackage = Metapackage.new(params[:metapackage])

    respond_to do |format|
      if @metapackage.save
        flash[:notice] = 'Metapackage was successfully created.'
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
        format.html { redirect_to("/distributions/" + meta.distribution_id.to_s + "/metapackages/" + \
            meta.id + "/show") }
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
    @metapackage = Metapackage.find(params[:id])
    @metapackage.destroy

    respond_to do |format|
      format.html { redirect_to(metapackages_url) }
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
  
  def remove_package
    if Metacontent.delete(params[:package_id]).nil?
      flash[:error] = "Couldn't remove package from Meta Package"
    end
    redirect_to :controller => :metapackages, :action => :show, :id => params[:id] 
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
