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

class DerivativesController < ApplicationController
  layout 'application'
  
  def title
    t(:ubuntu_derivatives)
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
        flash[:notice] = t(:controller_derivatives_1)
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
        flash[:notice] = t(:controller_derivatives_2)
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

  def migrate
    der_old = Derivative.find(params[:derivative][:id])
    der_new = Derivative.find(params[:id])
    der_new.migrate_bundles(der_old)
    Metapackage.all.each do |b|
      b.debianize([der_new])
    end
    redirect_to(derivatives_url)
  end
  
end
