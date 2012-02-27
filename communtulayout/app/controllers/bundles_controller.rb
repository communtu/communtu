class BundlesController < ApplicationController
  # GET /bundles
  # GET /bundles.json
  def index
    @bundles = Bundle.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @bundles }
    end
  end

  # GET /bundles/1
  # GET /bundles/1.json
  def show
    @bundle = Bundle.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @bundle }
    end
  end

  # GET /bundles/new
  # GET /bundles/new.json
  def new
    @bundle = Bundle.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @bundle }
    end
  end

  # GET /bundles/1/edit
  def edit
    @bundle = Bundle.find(params[:id])
  end

  # POST /bundles
  # POST /bundles.json
  def create
    @bundle = Bundle.new(params[:bundle])

    respond_to do |format|
      if @bundle.save
        format.html { redirect_to @bundle, :notice => 'Bundle was successfully created.' }
        format.json { render :json => @bundle, :status => :created, :location => @bundle }
      else
        format.html { render :action => "new" }
        format.json { render :json => @bundle.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /bundles/1
  # PUT /bundles/1.json
  def update
    @bundle = Bundle.find(params[:id])

    respond_to do |format|
      if @bundle.update_attributes(params[:bundle])
        format.html { redirect_to @bundle, :notice => 'Bundle was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @bundle.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /bundles/1
  # DELETE /bundles/1.json
  def destroy
    @bundle = Bundle.find(params[:id])
    @bundle.destroy

    respond_to do |format|
      format.html { redirect_to bundles_url }
      format.json { head :ok }
    end
  end
end
