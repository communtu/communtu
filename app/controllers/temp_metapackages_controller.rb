class TempMetapackagesController < ApplicationController
  # GET /temp_metapackages
  # GET /temp_metapackages.xml
  def index
    @temp_metapackages = TempMetapackage.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @temp_metapackages }
    end
  end

  # GET /temp_metapackages/1
  # GET /temp_metapackages/1.xml
  def show
    @metapackage = TempMetapackage.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @metapackage }
    end
  end

  # GET /temp_metapackages/new
  # GET /temp_metapackages/new.xml
  def new
    @temp_metapackages = TempMetapackage.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @temp_metapackages }
    end
  end

  # GET /temp_metapackages/1/edit
  def edit
    @temp_metapackages = TempMetapackage.find(params[:id])
  end

  # POST /temp_metapackages
  # POST /temp_metapackages.xml
  def create
    @temp_metapackages = TempMetapackage.new(params[:temp_metapackages])

    respond_to do |format|
      if @temp_metapackages.save
        flash[:notice] = 'TempMetapackages erzeugt.'
        format.html { redirect_to(@temp_metapackages) }
        format.xml  { render :xml => @temp_metapackages, :status => :created, :location => @temp_metapackages }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @temp_metapackages.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /temp_metapackages/1
  # PUT /temp_metapackages/1.xml
  def update
    @temp_metapackages = TempMetapackage.find(params[:id])

    respond_to do |format|
      if @temp_metapackages.update_attributes(params[:temp_metapackages])
        flash[:notice] = 'TempMetapackages aktualisiert.'
        format.html { redirect_to(@temp_metapackages) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @temp_metapackages.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /temp_metapackages/1
  # DELETE /temp_metapackages/1.xml
  def destroy
    @temp_metapackages = TempMetapackage.find(params[:id])
    @temp_metapackages.destroy

    respond_to do |format|
      format.html { redirect_to(temp_metapackages_url) }
      format.xml  { head :ok }
    end
  end
  
  def new_cart
    
    exist = TempMetapackage.find(:first, :conditions => ["user_id=? AND name=?",\
      current_user.id, params[:new_name]])
      
    if exist.nil?
      params[:id] = params[:distribution_id] if not params[:distribution_id].nil?
      cart = TempMetapackage.new({ :name => params[:new_name], :user_id => current_user.id,\
        :distribution_id => params[:id]})
      if cart.save
        session[:meta_cart] = cart.id
      end 
    end
    
    render_cart
  end
  
  def add_to_cart
    if not session[:meta_cart].nil?
      package = TempMetacontent.find(:first,\
        :conditions => ["temp_metapackage_id=? AND package_id=?",\
        session[:meta_cart], params[:id]])
      if package.nil?
        TempMetacontent.create({ :package_id => params[:id],\
          :temp_metapackage_id => session[:meta_cart] })        
      end
      
    end
    render_cart
  end
 
  def goto_cart
    session[:meta_cart] = params[:id]
    render_cart
  end
  
  def go_up
   session[:meta_cart] = nil;
   render_cart
  end
 
  def clear_cart
    if not session[:meta_cart].nil?
      TempMetacontent.delete_all ["temp_metapackage_id=?", session[:meta_cart]]
    end
    render_cart
  end
  
  def delete_item_from_cart
    if not session[:meta_cart].nil? and not params[:id].nil?
      TempMetacontent.delete_all ["temp_metapackage_id=? AND package_id=?",\
      session[:meta_cart], params[:id]]
    end
    render_cart
  end
  
  def publish_cart
    @categories = Category.find(1)
    meta_cart  = TempMetapackage.find(params[:id])
    meta_cart.temp_metacontents
    if not meta_cart.nil?
      @meta_name = meta_cart.name
      @meta_description = meta_cart.description
      @meta_id = meta_cart.id
    end
  end
  
  def transform_cart
    
    meta_cart  = TempMetapackage.find(params[:id])
    if not meta_cart.nil? 
      license_type = 0
      meta_cart.temp_metacontents.each do |content|
        license_type = content.package.repository.license_type if content.package.repository.license_type > license_type   
      end
      #
      if not params[:overwrite].nil?
        meta = Metapackage.find(:first, :conditions => ["distribution_id=? AND name=?",\
         meta_cart.distribution_id, params[:meta_name] ])
        if not meta.nil?
          Metacontent.delete_all(["metapackage_id=?", meta.id])
        end
      end
      
      if meta.nil? or params[:overwrite].nil?
        meta = Metapackage.new({ :distribution_id => meta_cart.distribution_id,\
          :name => params[:meta_name] })
      end
      
      meta.description = params[:meta_description]
      meta.category_id = params[:category_id]
      meta.rating = params[:meta_level]
      meta.license_type = license_type
      meta.user_id = current_user.id
        
      if meta.save
        meta_cart.temp_metacontents.each do |content|
          Metacontent.create({ :metapackage_id => meta.id, :package_id => content.package_id })
        end
        
        TempMetacontent.delete_all [ "temp_metapackage_id=?", params[:id] ]
        TempMetapackage.delete(params[:id])
        session[:meta_cart] = nil
        flash[:notice] = "The Metapackage " +  params[:meta_name] + " was succesfully saved to " +\
          "Distribution " + meta.distribution.name
        redirect_to :controller => :metapackages, :action => :show, :id => meta.id
      else
        @categories = Category.find(1)
        @meta_name = params[:meta_name]
        @meta_description = params[:meta_description]
        @meta_id = params[:id]
        flash[:notice] = "The name of this Metapackage already exists for this distribution"
        render :action => :publish_cart
      end
    end
  end
  
  def save_cart
    temp = TempMetapackage.find(:first, :conditions => ["user_id=? AND id=?", current_user.id,\
      session[:meta_cart] ])
    temp.is_saved = 1
    temp.save
    session[:meta_cart] = nil
    redirect_to :controller => :users, :action => :meta_packages, :id => current_user.id
  end

  def reset_cart
    temp = TempMetapackage.find(:first, :conditions => ["user_id=? AND id=?", current_user.id,\
      params[:id] ])
    temp.is_saved = 0
    temp.save
    session[:meta_cart] = params[:id]
    render_cart 
  end
  
  def render_cart
    respond_to do |wants|
     wants.js { render :partial => 'meta_cart.html.erb'}
   end
  end
  
  def transform_to_temp
    meta = Metapackage.find(:first, :conditions => ["id=?",params[:id]] )
    meta.save_as_temp_meta current_user.id
    render_cart
  end
 
end
