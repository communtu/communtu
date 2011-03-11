# (c) 2008-2011 byllgemeinbildung e.V., Bremen, Germany
# This file is part of Communtu.

# Communtu is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# Communtu is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero Public License for more details.

# You should have received a copy of the GNU Affero Public License
# along with Communtu.  If not, see <http://www.gnu.org/licenses/>.

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
        flash[:notice] = t(:architecture_successful)
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
        flash[:notice] = t(:architecture_successful_updated)
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
