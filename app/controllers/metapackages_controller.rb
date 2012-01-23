# (c) 2008-2011 by Allgemeinbildung e.V., Bremen, Germany
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

class MetapackagesController < ApplicationController
  require 'lib/utils.rb'
  before_filter :login_required, :only => [:new_from_cart, :edit, :create, :update, :destroy, :publish, :edit_action, :remove_package, :bundle_from_selection]
  before_filter :check_administrator_role, :flash => { :notice => I18n.t(:no_admin) }, 
                :only => [:reset, :health_status, :migrate, :finish_migrate]

  def title
    if params[:action] == "show"
    "Communtu - " + t(:bundle) + ": " + @metapackage.name
    else
    t(:bundle)
    end
  end
  
  @@migrations = {}
    
  def index
    if is_admin? then
      @user_type = 1
    else
      @user_type = 2
    end
    @metapackages = sort_metalist({ :user => current_user, :session => session, :params => params }, @user_type)
  end

  def index_mine
    @user_type = 0
    @metapackages = sort_metalist({ :user => current_user, :session => session, :params => params }, @user_type)
    render :action => 'index'
  end
  # GET /metapackages/1
  # GET /metapackages/1.xml
  def show
    @metapackage = Metapackage.find(params[:id])
    show_aux
  end
  
  def show_aux
      if @metapackage.name_tid == nil
         #something get wrong - this cannot happend if the translation goes right
         @meta_english_title = ""
      else
         @meta_english_title = Translation.find(:first, :conditions => {:translatable_id => @metapackage.name_tid, :language_code => "en"})
      end
    @conflicts = {} # @metapackage.internal_conflicts  # should use edos-debcheck
    if logged_in?
      @distribution = current_user.distribution
      @derivative = current_user.derivative
    end
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @metapackage }
    end
  end

  def new_from_cart
    @metapackage = Metapackage.new
    @metapackage.category_id = 1
    @metapackage.version = "0.1"
    @name = params[:name]
    @categories  = Category.find(1)
    @conflicts   = {}
    render :action => :edit
  end

  # GET /metapackages/1/edit
  def edit
    # protect current cart
    if editing_metapackage?
      flash[:error] = t(:save_or_delete_bundle)
      redirect_to '/packages'
    else
      edit_new_or_cart
    end
  end

  def edit_new_or_cart
    @metapackage = Metapackage.find(params[:id])
    @meta_english_title = Translation.find(:first, :conditions => {:translatable_id => @metapackage.name_tid, :language_code => "en"})
    if !is_admin? and !check_owner(@metapackage,current_user) then
      redirect_to metapackage_path(@metapackage)
      return
    end
    @categories  = Category.find(1)
    @conflicts   = {}
    @name = if @metapackage.name == "" then t(:new_bundle) else  @metapackage.name end
    @name_english = if @metapackage.name_english == "" then "new bundle" else @metapackage.name_english end
    @description = if @metapackage.description.nil? then "" else @metapackage.description end
    @description_english = if @metapackage.description_english.nil? then "" else @metapackage.description_english end
    render :action => 'edit'
  end

  def create
    update
  end

  # PUT /metapackages/1
  # PUT /metapackages/1.xml
  def update
    error = false
    flash[:error] = ""
    # correction of nil entries
    if params[:distributions].nil? then
      params[:distributions] = []
    end
    if params[:derivatives].nil? then
      params[:derivatives] = []
    end
    if params[:id].nil?
      @metapackage = nil
    else
      @metapackage = Metapackage.find(params[:id])
    end
    @name = params[:metapackage][:name]
    @name_english = params[:metapackage][:name_english]
    if @name_english.nil? and !@metapackage.nil?
      @name_english = @metapackage.name_english
    end
    @description = params[:metapackage][:description]
    @description_english = params[:metapackage][:description_english]
    if @metapackage.nil?
      if check_bundle_name(params[:metapackage][:name])
         @metapackage = Metapackage.new

         @translation_new = Translation.new_translation(params[:metapackage][:name])
    		 @metapackage.name_tid = @translation_new.translatable_id

    		 @translation_des  = Translation.new_translation("")
    		 @metapackage.description_tid = @translation_des.translatable_id

         if I18n.locale.to_s != "en"
      			translate_name = Translation.new_translation("",:en)
      			translate_des = Translation.new_translation("",:en)
    	   end
         @metapackage.user_id = current_user.id
         @metapackage.default_install = false
         @metapackage.license_type = 0
         @metapackage.category_id = 1
         @metapackage.save!
         params[:id] = @metapackage.id
      else
        flash[:error] += t(:controller_metapackages_2)
        error = true
        params[:metapackage].delete(:description_english)
        params[:metapackage].delete(:name_english)
        @metapackage = Metapackage.new(params[:metapackage])
        @conflicts   = {}
        render :action => "edit" # TODO: we should keep all the selections
        return
      end
    end
    if !is_admin? and !check_owner(@metapackage,current_user) then
      redirect_to metapackage_path(@metapackage)
      return
    end
    @conflicts = {} # deprecated # Package.conflicts(params[:distributions],params[:derivatives])
    if !@conflicts.empty? then
        flash[:error] += t(:controller_metapackages_conflicts)
        error = true
    end
    if @metapackage.is_published? and !is_admin? then
      if !params[:metapackage][:name].nil? and params[:metapackage][:name]!=@metapackage.name then
        flash[:error] += t(:controller_metapackages_no_renaming)
        error = true
      end
    else
      if I18n.locale.to_s != "en"
	if !check_english_bundle_name(@name_english,@metapackage)
	  flash[:error] += t(:english_name_reserve)
          error = true
        end
      end
      if !check_bundle_name(params[:metapackage][:name],@metapackage)
        flash[:error] += t(:controller_metapackages_2)
        error = true
      end
    end
    if params[:metapackage][:version].nil? or params[:metapackage][:version].empty? then
      flash[:error] += t(:controller_metapackages_7)
      error = true
    elsif !Deb.check_version(params[:metapackage][:version]) then
      flash[:error] += t(:illformed_version)
      error = true
    end
    if !@metapackage.debianized_version.nil? \
       and !@metapackage.debianized_version.empty? \
       and !Deb.version_gt(params[:metapackage][:version],@metapackage.debianized_version) then
      flash[:error] += t(:controller_metapackages_8)
      error = true
    end
    if @description.nil? or @description.empty? then
      flash[:error] += t(:controller_metapackages_9)
      error = true
    end
    if editing_metapackage?
      if check_cart(@metapackage)
        flash[:error] += t(:circular_dependency)
        error = true
      end
    end
    if !error
      # mark bundle as modified
      @metapackage.modified = true
      if @metapackage.name_tid == nil and params[:metapackage][:name] != ""
        @translation_new  = Translation.new
        @translation_new.translatable_id = new_trans_id
        @metapackage.name_tid = @translation_new.translatable_id
        @translation_new.contents = params[:metapackage][:name]
        @translation_new.language_code = I18n.locale.to_s
        @translation_new.save
      end
      if params[:metapackage][:name] != "" and params[:metapackage][:name] != nil
        @trans_update_name = Translation.find(:first, :conditions => { :translatable_id => @metapackage.name_tid, :language_code => I18n.locale.to_s})
        if @trans_update_name == nil
          @trans_update_name = Translation.new
          @trans_update_name.translatable_id = @metapackage.name_tid
          @trans_update_name.contents = params[:metapackage][:name]
          @trans_update_name.language_code = I18n.locale.to_s
          @trans_update_name.save
        else
          @trans_update_name.contents = params[:metapackage][:name]
          @trans_update_name.save
        end
      end
        @trans_update_name_english = Translation.find(:first, :conditions => { :translatable_id => @metapackage.name_tid, :language_code => "en"})
      if params[:metapackage][:name_english] != nil
        if @trans_update_name_english == nil
          @trans_update_name_english = Translation.new
          @trans_update_name_english.translatable_id = @metapackage.name_tid
          @trans_update_name_english.contents = params[:metapackage][:name_english]
          @trans_update_name_english.language_code = "en"
          @trans_update_name_english.save
        else
          @trans_update_name_english.contents = params[:metapackage][:name_english]
          @trans_update_name_english.save
        end
      end
      if @description != "" and @description != nil
        if @metapackage.description_tid == nil
           @metapackage.description_tid = new_trans_id
        end
        @trans_update_des = Translation.find(:first, :conditions => { :translatable_id => @metapackage.description_tid, :language_code => I18n.locale.to_s})
        if @trans_update_des == nil
          @trans_update_des = Translation.new
          @trans_update_des.translatable_id = @metapackage.description_tid
          @trans_update_des.contents = @description
          @trans_update_des.language_code = I18n.locale.to_s
          @trans_update_des.save
        else
          @trans_update_des.contents = @description
          @trans_update_des.save
        end
      end
      @trans_update_description_english = Translation.find(:first, :conditions => { :translatable_id => @metapackage.description_tid, :language_code => "en"})
      if @description_english != nil
        if @trans_update_description_english == nil
          @trans_update_description_english = Translation.new
          @trans_update_description_english.translatable_id = @metapackage.description_tid
          @trans_update_description_english.contents = @description_english
          @trans_update_description_english.language_code = "en"
          @trans_update_description_english.save
        else
          @trans_update_description_english.contents = @description_english
          @trans_update_description_english.save
        end
      end
      @metapackage.conflict_msg = nil # conflicts need to be newly computed
      @metapackage.save
      if editing_metapackage?
        save_cart(@metapackage)
      end
      # save selection of distributions and deriviatives
      params[:distributions].each do |p, dists|
        mc = Metacontent.find(:first, :conditions => ["metapackage_id = ? and base_package_id = ?",@metapackage.id,p])
        if !mc.nil?
          mc.metacontents_distrs.each {|d| d.destroy} # delete all distributions
          dists.each {|d| mc.distributions << Distribution.find(d)}     # and add the selected ones
        end
      end
      params[:derivatives].each do |p, ders|
        mc = Metacontent.find(:first, :conditions => ["metapackage_id = ? and base_package_id = ?",@metapackage.id,p])
        if !mc.nil?
          mc.metacontents_derivatives.each {|d| d.destroy} # delete all derivatives
          ders.each {|d| mc.derivatives << Derivative.find(d)}             # and add the selected ones
        end
      end
      attrs = {:version => params[:metapackage][:version],:default_install => params[:metapackage][:default_install],:tested => params[:metapackage][:tested]}
      if !params[:metapackage][:category_id].nil? and !params[:metapackage][:category_id].empty?
        attrs[:category_id] = params[:metapackage][:category_id]
      end
      @metapackage.update_attributes(attrs)
      flash.delete(:error)
      redirect_to :action => :show, :id => @metapackage.id
    else # in case of error
      render :action => "edit" # TODO: we should keep all the selections
    end
  end

  def save
    @metapackage = Metapackage.find(params[:id])
    if @metapackage.name == ""
      @metapackage.name = t(:new_bundle)
    end
    if !is_admin?
      if !check_owner(@metapackage,current_user) then
        redirect_to metapackage_path(@metapackage)
        return
      end
    end
    if @metapackage.cant_be_debianized then
      flash[:error] = t(:cant_debianized)
      redirect_to edit_metapackage_path(@metapackage)
      return
    end
    #if !@metapackage.internal_conflicts.empty?
    #  flash[:error] = t(:controller_metapackages_no_save)
    #els
    if !@metapackage.modified
      flash[:notice] = t(:controller_metapackages_not_changed)
    elsif @metapackage.debianizing
      flash[:notice] = t(:controller_metapackages_debianizing)
    else
      @metapackage.debianize
      @metapackage.fork_generate_debs
    end
    redirect_to :action => :show, :id => @metapackage.id
  end
  # DELETE /metapackages/1
  # DELETE /metapackages/1.xml
  def destroy
    metapackage  = Metapackage.find(params[:id])   
    if !is_admin? and !check_owner(metapackage,current_user) then
      redirect_to metapackage_path(metapackage)
      return
    end
    if metapackage.is_published? then
      flash[:error] = t(:controller_metapackages_cannot_destroy)
      return  
    end
    m = Metacontent.find(:first,:conditions => ["base_package_id = ?",metapackage.id])
    if m != nil
      flash[:error] = t(:metapackages_cannot_destroy)
      redirect_to metapackage_path(metapackage)
      return
    end
    @translation_name = Translation.find(:all, :conditions => { :translatable_id => metapackage.name_tid })
    m = @translation_name.length
    e = 0
    m.times do
     @translation_name[e].delete
     e = e + 1
    end
    @translation_des = Translation.find(:all, :conditions => { :translatable_id => metapackage.description_tid })
    m = @translation_des.length
    e = 0
    m.times do
     @translation_des[e].delete
     e = e + 1
    end
    metapackage.destroy

    respond_to do |format|
      format.html { redirect_to("/metapackages/index_mine") }
      format.xml  { head :ok }
    end
  end
  
  def publish
    package = Metapackage.find(params[:id])
    if !check_owner(package,current_user) then
      redirect_to metapackage_path(package)
      return
    end
    # does bundle contain some unpublished bundle?
    unpublished_descendants = package.descendants.select{|b| !b.is_published? }
    if !unpublished_descendants.empty?
      names = unpublished_descendants.map{|b| self.class.helpers.link_to(b.name, metapackage_path(b))}.join(", ")
      flash[:error] = t(:cannot_publish_bundle, :bundles => names)      
    else
      package.published = 1
      package.modified = true
      package.save!
    end
    
    redirect_to :controller => :metapackages, :action => :show
  end
  
  def edit_packages(did = nil)
    @bundle = Metapackage.find(params[:id])
    # protect current cart
    if editing_metapackage? and Cart.find(session[:cart]).metapackage!=@bundle
      flash[:error] = t(:save_or_delete_bundle)
      redirect_to '/packages'
      return
    end
    if !is_admin? and !check_owner(@bundle,current_user) then
      redirect_to metapackage_path(@metapackage)
      return
    end
    card_editor(@bundle.name,@bundle.base_packages,session,current_user,@bundle.id,did.to_i)
  end
  
  def remove_package
    if !params[:metapackage_id].nil?
      m = Metapackage.find(params[:metapackage_id])
      if !m.nil? and !is_admin? and !check_owner(m,current_user) then
        redirect_to metapackage_url(m)
        return
      end
    end
    if editing_metapackage? then
      p = Package.find(params[:id])
      cart  = Cart.find(session[:cart])
      if !cart.nil? and !p.nil? then
        cart.base_packages.delete(p)
      end
      redirect_to :action => :edit, :id => params[:metapackage_id]
    else
      redirect_to :controller => :metapackages, :action => :edit_action, :id => params[:metapackage_id], :did => params[:id], :method=>:pedit
    end
  end
  
  def edit_action
    action = params[:method]
    meta   = Metapackage.find(params[:id])
    if !is_admin? and !check_owner(meta,current_user) then
      redirect_to metapackage_path(meta)
      return
    end
    if not meta.nil?
        if action == "edit"
            redirect_to metapackage_path(meta) + "/edit"
        elsif action == "pedit"
            edit_packages(params[:did])
        elsif action == "publish"
          publish
        elsif action == "delete"
             m = Metacontent.find(:first,:conditions => ["base_package_id = ?",meta.id])
            if !meta.is_published? and m == nil
              meta.destroy
	      redirect_to ("/metapackages/index_mine")
	    else            
              flash[:error] = t(:metapackages_cannot_destroy)
	      redirect_to metapackage_path(meta)
            end
        else    
            redirect_to metapackage_path(meta)
        end
    end
  end
  

  def migrate
    @distributions = Distribution.find(:all)
  end
  
  def finish_migrate
    @from_dist       = Distribution.find(params[:from_dist][:id])
    @to_dist         = Distribution.find(params[:to_dist][:id])
    
    metas = session[:packages]
    @not_found = {}
    if not metas.nil?
        metas.each do |key,value|
            if value[:select] == "1"
                meta = Metapackage.find(key)
                if not meta.nil?
                    @not_found[meta] = meta.migrate(@from_dist,@to_dist)
                end
            end
        end
    end
  end
  
  
  def add_comment
    @id = params[:id]
  end
  
  def save_comment
    c = Comment.new({ :metapackage_id => params[:id],\
      :user_id => current_user.id,\
      :comment => params[:comment] } )
    c.save 
    redirect_to :controller => :metapackages, :action => :show, :id => params[:id] 
  end
  
  def rdepends
    @metapackage = Metapackage.find(params[:id])
    @dependencies = @metapackage.structured_all_recursive_packages    
  end

  def reset
    @metapackage = Metapackage.find(params[:id])
    @metapackage.debianizing = false
    @metapackage.deb_error = false
    @metapackage.modified = true
    @metapackage.save
    Deb.find(:all,:conditions => ["metapackage_id = ? and generated = ?",@metapackage.id,false]).each do |d|
      d.generated = true

      d.save
    end
    flash[:notice] = t(:controller_metapackages_please_regenerate)
    redirect_to :action => :show, :id => params[:id]
  end
  
  def health_status
    @livecd_log = IO.popen("tail #{RAILS_ROOT}/log/livecd.log",&:read)
    @zombie_processes = IO.popen("ps -aef | grep defunct | grep -v grep | wc -l",&:read).to_i
    iso_path = SETTINGS['iso_path']
    @kvm_processes = IO.popen("ps -aef|grep kvm|grep -v grep",&:read).chomp.split("\n").count
    @cpu_usage = IO.popen("top -b -n 1 |grep Cpu",&:read)
    @cpu_usage_i = @cpu_usage.split(" ")[1].split("%")[0].to_i
    @free_isos = disk_free_space(iso_path)
    @free_home = disk_free_space("/home")
    @free_root = disk_free_space("/")
    @bundles_with_errors = (Metapackage.find_all_by_deb_error(true)).uniq
    @modified_bundles = Metapackage.find_all_by_modified(true) - @bundles_with_errors
    @bundles_without_debs = Metapackage.find_all_by_debianized_version_and_published(nil,1)
    @bundles_with_missing_debs = Metapackage.find(:all,:conditions=>["debs.generated = 0"],:include=>:debs)
    @bundles_with_missing_packages = {}
    Distribution.all.each do |d|
      nd = d.successor
      if !nd.nil?
        ms = Package.find_by_sql("SELECT base_packages.id AS pid, package_distrs.distribution_id, metacontents.metapackage_id, \
               COUNT(package_id) AS counter  FROM `package_distrs`  \
               LEFT JOIN base_packages ON (base_packages.id=package_distrs.package_id) \
               INNER JOIN metacontents ON (base_packages.id = metacontents.base_package_id) \
               INNER JOIN metacontents_distrs ON (metacontents.id = metacontents_distrs.metacontent_id)  \
               WHERE package_distrs.distribution_id IN (#{d.id},#{nd.id}) \
               GROUP BY package_id HAVING counter = 1 AND distribution_id = #{d.id}")
        @bundles_with_missing_packages[d] = ms
      end
    end
    @bundles_with_conflicts = Metapackage.find(:all,:conditions=>["conflict_msg IS NOT NULL and conflict_msg != ?",""])
    @repositories_without_packages_all =
      Repository.all.select{|r| PackageDistr.find_by_repository_id(r.id).nil?}
    @repositories_without_packages =
      @repositories_without_packages_all.select{ |r| r.empty_files?}
    @repositories_incompletely_read = @repositories_without_packages_all - @repositories_without_packages
    failed_cds = Livecd.find(:all,:conditions => {:failed=>true})
    @failed_live_cds_count = failed_cds.size
    @failed_live_cds = {}
    failed_cds.each do |cd|
      tiny_log = cd.short_log[0,20]
      if @failed_live_cds[tiny_log].nil? then
        @failed_live_cds[tiny_log] = [cd]
      else
        @failed_live_cds[tiny_log] << cd
      end
    end
    ms=Metapackage.all.select{|m| Metacontent.find(:first,:conditions=>["metacontents_distrs.distribution_id = 6 and metapackage_id = ?",m.id],:include=>:metacontents_distrs).nil?}
  end

  def bundle_from_selection
    prepare_create
    cart = Cart.find(session[:cart])
    current_user.user_packages.map(&:base_package).uniq.each do |m|
       CartContent.create({:cart_id => cart.id, :base_package_id => m.id})
    end
    redirect_to "/packages"
  end

  def install
    session[:bundle] = params[:id]
    session[:path] = "install_bundle"
    redirect_to :action => "install_current"
  end

  def install_current
    @metapackage  = Metapackage.find_by_id(session[:bundle])
    if @metapackage.nil?
      flash[:error] = t(:no_bundle_selected)
      redirect_to :action => 'index'
    else
      show_aux
    end  
  end
  
  def install_current_sources
  end
  
  def install_current_bundle
    @metapackage  = Metapackage.find_by_id(session[:bundle])
  end
  
  def compute_conflicts
    @metapackage = Metapackage.find(params[:id])
    @metapackage.edos_conflicts
    redirect_to session[:backlink]
  end

private

  def check_owner(meta,user)
    if meta.nil? then
      flash[:error] = t(:controller_metapackages_bundle_not_found)
      return false
    end
    ok = meta.user==user
    if !ok then
      flash[:error] = t(:controller_metapackages_not_allowed)
    end
    return ok
  end

end
