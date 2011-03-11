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

class DistributionsController < ApplicationController
  
  def title
    t(:controller_distributions_0)
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
    require "lib/utils.rb"
    @distribution = Distribution.find(params[:id])
  end
  
  # POST /distributions
  # POST /distributions.xml
  def create
    @distribution = Distribution.new(params[:distribution])
    @translation1 = Translation.new
    @translation2 = Translation.new
    @last_trans = Translation.find(:first, :order => "translatable_id DESC")
    last_id = @last_trans.translatable_id
    @translation1.translatable_id = last_id + 1
    @translation1.contents = params[:distribution][:description]
    @translation2.translatable_id = last_id + 2
    @translation2.contents = params[:distribution][:url]
    @distribution.description_tid = last_id + 1
    @distribution.url_tid = last_id + 2
    @translation1.language_code = I18n.locale.to_s
    @translation2.language_code = I18n.locale.to_s
    @translation1.save
    @translation2.save
    respond_to do |format|
      if @distribution.save
        flash[:notice] = t(:controller_distributions_1)
        format.html { redirect_to(distributions_url) }
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
    @trans_update_des = Translation.find(:first, :conditions => { :translatable_id => @distribution.description_tid, :language_code => I18n.locale.to_s})
    if @trans_update_des == nil
      @trans_update_des = Translation.new
      @trans_update_des.translatable_id = @distribution.description_tid
      @trans_update_des.contents = params[:distribution][:description]
      @trans_update_des.language_code = I18n.locale.to_s
    else
    @trans_update_des.contents = params[:distribution][:description]
    end
    @trans_update_des.save
    @trans_update_url = Translation.find(:first, :conditions =>
        { :translatable_id => @distribution.url_tid, :language_code => I18n.locale.to_s})
    if @trans_update_url == nil
      @trans_update_url = Translation.new
      @trans_update_url.translatable_id = @distribution.url_tid
      @trans_update_url.contents = params[:distribution][:url]
      @trans_update_url.language_code = I18n.locale.to_s
    else
    @trans_update_url.contents = params[:distribution][:url]
    end
    @trans_update_url.save
    respond_to do |format|
      if @distribution.update_attributes(params[:distribution])
        flash[:notice] = t(:controller_distributions_2)
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
    @translation_url = Translation.find(:all, :conditions => { :translatable_id => @distribution.url_tid })
    m = @translation_url.count
    e = 0
    m.times do
     @translation_url[e].delete
     e = e + 1
    end
    @translation_des = Translation.find(:all, :conditions => { :translatable_id => @distribution.description_tid })
    m = @translation_des.count
    e = 0
    m.times do
     @translation_des[e].delete
     e = e + 1
    end
    @distribution.destroy
    
    respond_to do |format|
      format.html { redirect_to(distributions_url) }
      format.xml  { head :ok }
    end
  end

  def migrate
    @new_dist = Distribution.find(params[:id])
    @old_dist = @new_dist.predecessor
    # only proceed if new distribution is new and fresh
    if @old_dist.nil? or !Repository.find_by_distribution_id(@new_dist.id).nil? then
      flash[:error] = t(:cannot_migrate)
    else
      @old_dist.repositories.each do |r|
        r.migrate(@new_dist)
      end
    end
    redirect_to(distributions_url)
  end

  def migrate_bundles
    @new_dist = Distribution.find(params[:id])
    @old_dist = @new_dist.predecessor
    # only proceed if new distribution is snychronised and fresh
    if @old_dist.nil? or !MetacontentsDistr.find_by_distribution_id(@new_dist.id).nil? then
      flash[:error] = t(:cannot_migrate)
    elsif PackageDistr.find_by_distribution_id(@new_dist.id).nil?
      flash[:error] = t(:first_sync_repos)
    else
      Metapackage.all.each do |m|
        m.migrate(@old_dist, @new_dist)
      end
    end
    redirect_to(distributions_url)
  end

  def make_visible
    @dist = Distribution.find(params[:id])
    @dist.invisible = false
    @dist.save
    redirect_to(distributions_url)
  end

  def make_final
    @dist = Distribution.find(params[:id])
    @dist.preliminary = false
    @dist.save
    redirect_to(distributions_url)
  end

end
