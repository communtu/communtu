# (c) 2008-2010 by Verein Allgemeinbildung e.V., Bremen, Germany
# use, modification or distribution only with permission of the copyright holder

class DebsController < ApplicationController
  def title
    t(:controller_debs_0)
  end
  # GET /debs
  # GET /debs.xml
  def index
    @debs = Deb.find_all_by_generated(false)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @debs }
    end
  end

  # GET /debs/1
  # GET /debs/1.xml
  def show
    @deb = Deb.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @deb }
    end
  end

  # GET /debs/new
  # GET /debs/new.xml
  def new
    @deb = Deb.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @deb }
    end
  end

  # GET /debs/1/edit
  def edit
    @deb = Deb.find(params[:id])
  end

  # POST /debs
  # POST /debs.xml
  def create
    @deb = Deb.new(params[:deb])

    respond_to do |format|
      if @deb.save
        flash[:notice] = t(:controller_debs_1)
        format.html { redirect_to(@deb) }
        format.xml  { render :xml => @deb, :status => :created, :location => @deb }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @deb.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /debs/1
  # PUT /debs/1.xml
  def update
    @deb = Deb.find(params[:id])

    respond_to do |format|
      if @deb.update_attributes(params[:deb])
        flash[:notice] = t(:controller_debs_2)
        format.html { redirect_to(@deb) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @deb.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /debs/1
  # DELETE /debs/1.xml
  def destroy
    @deb = Deb.find(params[:id])
    @deb.destroy

    respond_to do |format|
      format.html { redirect_to(debs_url) }
      format.xml  { head :ok }
    end
  end
  
  def generate
    @deb = Deb.find(params[:id])
    # this may take very long, hence fork
    flash[:notice] =  t(:deb_generation_in_background)
    fork do
      ActiveRecord::Base.connection.reconnect!
      @deb.generate
    end
    ActiveRecord::Base.connection.reconnect!
    redirect_to(deb_path(@deb))
  end

  def generate_all
    @debs = Deb.find_all_by_generated(false)
    # this may take very long, hence fork
    flash[:notice] =  t(:deb_generation_in_background)
    fork do
      ActiveRecord::Base.connection.reconnect!
      @debs.each {|deb| deb.generate}
    end
    ActiveRecord::Base.connection.reconnect!
    redirect_to(debs_url)
  end

  def bundle
    @bundle = Metapackage.find(params[:id])
    @debs = Deb.find_all_by_metapackage_id_and_generated(params[:id],false)
  end

  def generate_bundle
    @debs = Deb.find_all_by_metapackage_id_and_generated(params[:id],false)
    # this may take very long, hence fork
    flash[:notice] =  t(:deb_generation_in_background)
    fork do
      ActiveRecord::Base.connection.reconnect!
      @debs.each {|deb| deb.generate}
    end
    ActiveRecord::Base.connection.reconnect!
    redirect_to :action => 'bundle', :id => params[:id]
  end
end
