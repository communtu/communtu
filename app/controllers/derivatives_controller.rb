class DerivativesController < ApplicationController
  layout 'application'
  
  def title
    _("Ubuntu Derivate")
  end
  # GET /derivatives
  # GET /derivatives.xml
  def index
    @derivatives = Derivative.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @derivatives }
    end
  end

  # GET /derivatives/1
  # GET /derivatives/1.xml
  def show
    @derivative = Derivative.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @derivative }
    end
  end

  # GET /derivatives/new
  # GET /derivatives/new.xml
  def new
    @derivative = Derivative.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @derivative }
    end
  end

  # GET /derivatives/1/edit
  def edit
    @derivative = Derivative.find(params[:id])
  end

  # POST /derivatives
  # POST /derivatives.xml
  def create
    @derivative = Derivative.new(params[:derivative])

    respond_to do |format|
      if @derivative.save
        flash[:notice] = _('Derivative erzeugt.')
        format.html { redirect_to(@derivative) }
        format.xml  { render :xml => @derivative, :status => :created, :location => @derivative }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @derivative.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /derivatives/1
  # PUT /derivatives/1.xml
  def update
    @derivative = Derivative.find(params[:id])

    respond_to do |format|
      if @derivative.update_attributes(params[:derivative])
        flash[:notice] = _('Derivat aktualisiert.')
        format.html { redirect_to(@derivative) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @derivative.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /derivatives/1
  # DELETE /derivatives/1.xml
  def destroy
    @derivative = Derivative.find(params[:id])
    @derivative.destroy

    respond_to do |format|
      format.html { redirect_to(derivatives_url) }
      format.xml  { head :ok }
    end
  end
end
