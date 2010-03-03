class GroupsController < ApplicationController
  # GET /groups
  # GET /groups.xml
  def index
    @groups = Group.find(:all)
  end

  # GET /groups/1
  # GET /groups/1.xml
  def show
    @group = Group.find(params[:id])
  end

  # GET /groups/new
  # GET /groups/new.xml
  def new
    @group = Group.new
  end

  # GET /groups/1/edit
  def edit
    @group = Group.find(params[:id])
  end

  # POST /groups
  # POST /groups.xml
  def create
    @group = Group.new(params[:group].merge({:owner_id => current_user.id}))

    respond_to do |format|
      if @group.save
        @group.users << current_user # adds the user to the group
        flash[:notice] = 'Group was successfully created.'
        format.html { redirect_to(@group) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /groups/1
  # PUT /groups/1.xml
  def update
    @group = Group.find(params[:id])

    respond_to do |format|
      if @group.update_attributes(params[:group])
        flash[:notice] = 'Group was successfully updated.'
        format.html { redirect_to(@group) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /groups/1
  # DELETE /groups/1.xml
  def destroy
    @group = Group.find(params[:id])
    @group.destroy

    respond_to do |format|
      format.html { redirect_to(groups_url) }
    end
  end
end
