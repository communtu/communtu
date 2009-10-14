class ArchitecturesController < ApplicationController
  # GET /architectures
  # GET /architectures.xml
  def index
    @architectures = Architecture.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @architectures }
    end
  end

  # GET /architectures/1
  # GET /architectures/1.xml
  def show
    @architecture = Architecture.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @architecture }
    end
  end

  # GET /architectures/new
  # GET /architectures/new.xml
  def new
    @architecture = Architecture.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @architecture }
    end
  end

  # GET /architectures/1/edit
  def edit
    @architecture = Architecture.find(params[:id])
  end

  # POST /architectures
  # POST /architectures.xml
  def create
    @architecture = Architecture.new(params[:architecture])

    respond_to do |format|
      if @architecture.save
        flash[:notice] = 'Architecture was successfully created.'
        format.html { redirect_to(@architecture) }
        format.xml  { render :xml => @architecture, :status => :created, :location => @architecture }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @architecture.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /architectures/1
  # PUT /architectures/1.xml
  def update
    @architecture = Architecture.find(params[:id])

    respond_to do |format|
      if @architecture.update_attributes(params[:architecture])
        flash[:notice] = 'Architecture was successfully updated.'
        format.html { redirect_to(@architecture) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @architecture.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /architectures/1
  # DELETE /architectures/1.xml
  def destroy
    @architecture = Architecture.find(params[:id])
    @architecture.destroy

    respond_to do |format|
      format.html { redirect_to(architectures_url) }
      format.xml  { head :ok }
    end
  end
end
