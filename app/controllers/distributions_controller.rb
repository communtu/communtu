class DistributionsController < ApplicationController
  
  def title
    _("Ubuntu Distributionen")
  end
  # GET /distributions
  # GET /distributions.xml
  def index
    @distributions = Distribution.find(:all, :order => 'short_name DESC')
    session[:search] = nil
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @distributions }
    end
  end

  # GET /distributions/1
  # GET /distributions/1.xml
  def show
    @distribution = Distribution.find(params[:id])
    session[:search] = nil
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @distribution }
    end
  end

  # GET /distributions/new
  # GET /distributions/new.xml
  def new
    @distribution = Distribution.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @distribution }
    end
  end

  # GET /distributions/1/edit
  def edit
    @distribution = Distribution.find(params[:id])
  end

  # POST /distributions
  # POST /distributions.xml
  def create
    @distribution = Distribution.new(params[:distribution])

    respond_to do |format|
      if @distribution.save
        flash[:notice] = _('Distribution erzeugt.')
        format.html { redirect_to(@distribution) }
        format.xml  { render :xml => @distribution, :status => :created, :location => @distribution }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @distribution.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /distributions/1
  # PUT /distributions/1.xml
  def update
    @distribution = Distribution.find(params[:id])

    respond_to do |format|
      if @distribution.update_attributes(params[:distribution])
        flash[:notice] = _('Distribution aktualisiert.')
        format.html { redirect_to(@distribution) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @distribution.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /distributions/1
  # DELETE /distributions/1.xml
  def destroy
    @distribution = Distribution.find(params[:id])
    @distribution.destroy
    
    respond_to do |format|
      format.html { redirect_to(distributions_url) }
      format.xml  { head :ok }
    end
  end
end
