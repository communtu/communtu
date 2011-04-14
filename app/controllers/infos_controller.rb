class InfosController < ApplicationController
  before_filter :check_administrator_role, :only => [:create, :update, :new, :edit]
  # GET /infos
  # GET /infos.xml
  def index
    @infos = Info.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @infos }
    end
  end

  # GET /infos/1
  # GET /infos/1.xml
  def show
    @info = Info.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @info }
    end
  end

  # GET /infos/new
  # GET /infos/new.xml
  def new
    @info = Info.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @info }
    end
  end

  # GET /infos/1/edit
  def edit
    @info = Info.find(params[:id])
  end

  # POST /infos
  # POST /infos.xml
  def create
    @info = Info.new
    @info.author = current_user
    @info.content_tid = Translation.new_translation(params[:info][:content]).translatable_id
    @info.header_tid = Translation.new_translation(params[:info][:header]).translatable_id

    respond_to do |format|
      if @info.save
        flash[:notice] = 'Info was successfully created.'
        format.html { redirect_to(@info) }
        format.xml  { render :xml => @info, :status => :created, :location => @info }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @info.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /infos/1
  # PUT /infos/1.xml
  def update
    @info = Info.find(params[:id])

    @info.author = current_user
    @info.content_tid = Translation.new_translation(params[:info][:content]).translatable_id
    @info.header_tid = Translation.new_translation(params[:info][:header]).translatable_id

    respond_to do |format|
      if @info.save
        flash[:notice] = 'Info was successfully updated.'
        format.html { redirect_to(@info) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @info.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /infos/1
  # DELETE /infos/1.xml
  def destroy
    @info = Info.find(params[:id])
    @info.destroy

    respond_to do |format|
      format.html { redirect_to(infos_url) }
      format.xml  { head :ok }
    end
  end

  def rss
    @infos = Info.find(:all, :order => "id DESC", :limit => 10)
    render :layout => false
    response.headers["Content-Type"] = "application/xml; charset=utf-8"
  end

end
