# (c) 2008-2010 by Verein Allgemeinbildung e.V., Bremen, Germany
# use, modification or distribution only with permission of the copyright holder

class RepositoriesController < ApplicationController
  before_filter :login_required
  before_filter :check_administrator_role, :only => [:sync_package, :sync_all, :test_all], :flash => { :notice => I18n.t(:no_admin) }

  def title
    t(:controller_repositories_0)
  end  
  # GET /repositories
  # GET /repositories.xml
  def index
    @repositories = Repository.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @repositories }
    end
  end

  # GET /repositories/1
  # GET /repositories/1.xml
  def show
    @repository = Repository.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @repository }
    end
  end

  # GET /repositories/new
  # GET /repositories/new.xml
  def new
    @repository = Repository.new
    @repository.distribution_id = params[:distribution_id]
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @repository }
    end
  end

  def multinew
    @distribution = Distribution.find(params[:id])    
  end

  # GET /repositories/1/edit
  def edit
    @repository = Repository.find(params[:id])
    @distributions = Distribution.find(:all)
  end

  # POST /repositories
  # POST /repositories.xml
  def create
    @repository = Repository.new(params[:repository])
    @repository.distribution_id = params[:distribution_id]
    
    respond_to do |format|
      if @repository.save
        flash[:notice] = t(:controller_repositories_1)
        format.html { redirect_to(distribution_path(params[:distribution_id])) }
        format.xml  { render :xml => @repository, :status => :created, :location => @repository }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @repository.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /repositories/1
  # PUT /repositories/1.xml
  def update
    @repository = Repository.find(params[:id])
    
    respond_to do |format|
      if @repository.update_attributes(params[:repository])
        flash[:notice] = t(:controller_repositories_2)
        # update dependencies
        @repository.repositories.each do |r|
          if params[:repo][r.id].nil?
            @repository.repositories.delete(r)
          end
        end
        params[:repo].each do |id,x|
          begin
            r = Repository.find(id)
            if !@repository.repositories.include?(r)
              @repository.repositories << r
            end
          end
        end
        format.html { redirect_to({ :controller => :distributions, :action => :show,\
          :id => @repository.distribution_id }) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @repository.errors, :status => :unprocessable_entity }
      end
    end
  end

  def multicreate
    if !params[:file][:name].nil?
      params[:file][:name].read.split("\n").each do |r|
        parts = r.split(" ")
        if !parts[0].nil? && !parts[0][0].nil? && parts[0][0]!='#'[0] then
          for i in 3..parts.length-1 do
            @repository = Repository.new
            @repository.distribution_id = params[:id]
            @repository.security_type = 0
            @repository.license_type = 0
            @repository.url = parts[0]+" "+parts[1]+" "+parts[2] 
            @repository.subtype = parts[i] 
            @repository.save
          end  
        end  
      end
      flash[:notice] = t(:controller_repositories_3)
    end
    redirect_to(distribution_path(params[:id])) 
  end

  # DELETE /repositories/1
  # DELETE /repositories/1.xml
  def destroy
    @repository = Repository.find(params[:id])
    @distribution = @repository.distribution
    @repository.destroy

    respond_to do |format|
      format.html { redirect_to distribution_path(@distribution) }
      format.xml  { head :ok }
    end
  end

  def migrate
    @repository = Repository.find(params[:id])    
  end

  def finish_migrate
    @repository = Repository.find(params[:id]) 
    @distribution = Distribution.find(params[:distribution][:id])
    if !@repository.nil? && !@distribution.nil? then
      @repository.migrate(@distribution)
      render(:action=> 'show')
    else
      redirect_to('migrate'+params[:id].to_s)
    end
  end

  def sync_package
    @repository = Repository.find(params[:id])
    @info = @repository.import_source
  end

  def force_sync
    @repository = Repository.find(params[:id])
    @info = @repository.import_source(true)
    render :action => :sync_package
  end

  def sync_all
    @distribution = Distribution.find(params[:id])
    @infos = @distribution.repositories.map { |r| r.import_source }
  end

  def test_all
    @distribution = Distribution.find(params[:id])
    @infos = @distribution.test_all_repos
  end

end
