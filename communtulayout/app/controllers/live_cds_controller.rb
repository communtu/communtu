class LiveCdsController < ApplicationController
  # GET /live_cds
  # GET /live_cds.json
  def index
    @live_cds = LiveCd.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @live_cds }
    end
  end
  
  def bestof
    @live_cds = LiveCd.bestof
    render :action => "index"
  end

  # GET /live_cds/1
  # GET /live_cds/1.json
  def show
    @live_cd = LiveCd.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @live_cd }
    end
  end

  # GET /live_cds/new
  # GET /live_cds/new.json
  def new
    @live_cd = LiveCd.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @live_cd }
    end
  end

  # GET /live_cds/1/edit
  def edit
    @live_cd = LiveCd.find(params[:id])
  end

  # POST /live_cds
  # POST /live_cds.json
  def create
    @live_cd = LiveCd.new(params[:live_cd])

    respond_to do |format|
      if @live_cd.save
        format.html { redirect_to @live_cd, :notice => 'Live cd was successfully created.' }
        format.json { render :json => @live_cd, :status => :created, :location => @live_cd }
      else
        format.html { render :action => "new" }
        format.json { render :json => @live_cd.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /live_cds/1
  # PUT /live_cds/1.json
  def update
    @live_cd = LiveCd.find(params[:id])

    respond_to do |format|
      if @live_cd.update_attributes(params[:live_cd])
        format.html { redirect_to @live_cd, :notice => 'Live cd was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @live_cd.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /live_cds/1
  # DELETE /live_cds/1.json
  def destroy
    @live_cd = LiveCd.find(params[:id])
    @live_cd.destroy

    respond_to do |format|
      format.html { redirect_to live_cds_url }
      format.json { head :ok }
    end
  end
  
  def build
    @live_cds = LiveCd.bestof
    @categories = LiveCd.categories
  end
  
  def advanced_build
    
  end
  
end
