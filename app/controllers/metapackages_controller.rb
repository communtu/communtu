class MetapackagesController < ApplicationController
  before_filter :login_required
  before_filter :is_anonymous, :only => :publish
  before_filter :check_administrator_role, :flash => { :notice => I18n.t(:no_admin) }, :only => :reset

  def title
    t(:bundle)
  end

  @@migrations = {}
    

  # GET /metapackages/1
  # GET /metapackages/1.xml
  def show
    @metapackage = Metapackage.find(params[:id])
    @meta_english_title = Translation.find(:first, :conditions => {:translatable_id => @metapackage.name_tid, :language_code => "en"})
    if @meta_english_title == nil
#      @meta_english_title = ""
      @meta_english_title.contents = "unknown"
    end
    @conflicts = @metapackage.internal_conflicts
    if logged_in?
    @distribution = current_user.distribution
    @derivative = current_user.derivative
    end
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @metapackage }
    end
  end

  # GET /metapackages/new
  # GET /metapackages/new.xml
  def new
    @metapackage = Metapackage.new
    @metapackage.name = t(:new_bundle)
    @backlink    = request.env['HTTP_REFERER']                            
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @metapackage }
    end
  end

  # GET /metapackages/1/edit
  def edit
    @metapackage = Metapackage.find(params[:id])
    @meta_english_title = Translation.find(:first, :conditions => {:translatable_id => @metapackage.name_tid, :language_code => "en"})
    if !check_owner(@metapackage,current_user) then
      redirect_to metapackage_path(@metapackage)
      return
    end
    @categories  = Category.find(1)
    @backlink    = request.env['HTTP_REFERER']
    @conflicts   = {}
  end

  # PUT /metapackages/1
  # PUT /metapackages/1.xml
  def update 
    error = false
    flash[:error] = ""
    @metapackage = Metapackage.find(params[:id])
    if !check_owner(@metapackage,current_user) then
      redirect_to metapackage_path(@metapackage)
      return
    end
    @conflicts = @metapackage.internal_conflicts
    if !@conflicts.empty? then
        flash[:error] += t(:controller_metapackages_conflicts)
        error = true
    end
    if @metapackage.is_published? then
      if !params[:metapackage][:name].nil? and params[:metapackage][:name]!=@metapackage.name then
        flash[:error] += t(:controller_metapackages_no_renaming)
        error = true
      end
    else
      # compute debian names of existing metapackages, without "communtu-" oder "communtu-private-bundle-" prefix
      metanames = (Metapackage.all-[@metapackage]).map{|m| BasePackage.debianize_name(m.name)}
      if params[:metapackage][:name]==t(:new_bundle) or metanames.include?(BasePackage.debianize_name(params[:metapackage][:name])) then
        flash[:error] += t(:controller_metapackages_6)
        error = true
      end
    end
    if params[:metapackage][:version].nil? or params[:metapackage][:version].empty? then
      flash[:error] += t(:controller_metapackages_7)
      error = true
    end
    if !@metapackage.debianized_version.nil? \
       and !@metapackage.debianized_version.empty? \
       and !Deb.version_gt(params[:metapackage][:version],@metapackage.debianized_version) then
      flash[:error] += t(:controller_metapackages_8)
      error = true
    end
    if params[:metapackage][:description].nil? or params[:metapackage][:description].empty? then
      flash[:error] += t(:controller_metapackages_9)
      error = true
    end  
    # correction of nil entries
    if params[:distributions].nil? then
      params[:distributions] = []
    end
    if params[:derivatives].nil? then
      params[:derivatives] = []
    end
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
    if params[:metapackage][:description] != "" and params[:metapackage][:description] != nil
    if @metapackage.description_tid == nil
       @metapackage.description_tid = new_trans_id
    end
    @trans_update_des = Translation.find(:first, :conditions => { :translatable_id => @metapackage.description_tid, :language_code => I18n.locale.to_s})
    if @trans_update_des == nil
      @trans_update_des = Translation.new
      @trans_update_des.translatable_id = @metapackage.description_tid
      @trans_update_des.contents = params[:metapackage][:description]
      @trans_update_des.language_code = I18n.locale.to_s
      @trans_update_des.save
    else
      @trans_update_des.contents = params[:metapackage][:description]
      @trans_update_des.save
    end   
    end
      @trans_update_description_english = Translation.find(:first, :conditions => { :translatable_id => @metapackage.description_tid, :language_code => "en"})
    if params[:metapackage][:description_english] != nil  
      if @trans_update_description_english == nil
        @trans_update_description_english = Translation.new
        @trans_update_description_english.translatable_id = @metapackage.description_tid
        @trans_update_description_english.contents = params[:metapackage][:description_english]
        @trans_update_description_english.language_code = "en"
        @trans_update_description_english.save
      else
        @trans_update_description_english.contents = params[:metapackage][:description_english]
        @trans_update_description_english.save
      end
    end
    @metapackage.save
    # save selection of distributions and deriviatives
    params[:distributions].each do |p, dists|
      mc = Metacontent.find(:first, :conditions => ["metapackage_id = ? and base_package_id = ?",@metapackage.id,p])
      mc.metacontents_distrs.each {|d| d.destroy} # delete all distributions
      dists.each {|d| mc.distributions << Distribution.find(d)}     # and add the selected ones
    end
    params[:derivatives].each do |p, ders|
      mc = Metacontent.find(:first, :conditions => ["metapackage_id = ? and base_package_id = ?",@metapackage.id,p])
      mc.metacontents_derivatives.each {|d| d.destroy} # delete all derivatives
      ders.each {|d| mc.derivatives << Derivative.find(d)}             # and add the selected ones
    end
#    respond_to do |format|
      # save other attributes
      if !error 
         @metapackage.update_attributes(:version => params[:metapackage][:version],:category_id => params[:metapackage][:category_id],:default_install => params[:metapackage][:default_install])
 #       @metapackage.update_attributes(params[:metapackage])
#:name => params[:metapackage][:name],:description => params[:metapackage][:description],
        flash.delete(:error)
#        format.html { redirect_to :action => :show, :id => @metapackage.id }
#        format.xml  { head :ok }
        redirect_to :action => :show, :id => @metapackage.id
      else
#        format.html { render :action => "edit" }
#        format.xml  { render :xml => @metapackage.errors, :status => :unprocessable_entity }
        render :action => "edit"
#      end
    end
  end

  def save
    @metapackage = Metapackage.find(params[:id])
    if @metapackage.name == ""
      @metapackage.name = t(:new_bundle)
    end
    if !is_admin? and !check_owner(@metapackage,current_user) then
      redirect_to metapackage_path(@metapackage)
      return
    end
    if @metapackage.cant_be_debianized then
      flash[:error] = t(:cant_debianized)
      redirect_to edit_metapackage_path(@metapackage)
      return
    end
    if !@metapackage.internal_conflicts.empty?
      flash[:error] = t(:controller_metapackages_no_save)
    elsif !@metapackage.modified
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
      format.html { redirect_to(user_path(current_user) + "/metapackages/0") }
      format.xml  { head :ok }
    end
  end
  
  def publish
    package = Metapackage.find(params[:id]);
    if !check_owner(package,current_user) then
      redirect_to metapackage_path(package)
      return
    end
    package.published = Metapackage.state[:published]
    package.modified = true
    package.save!
    
    redirect_to :controller => :metapackages, :action => :show
  end
  
  def edit_packages
    @package = Metapackage.find(params[:id]);
    if !check_owner(@package,current_user) then
      redirect_to metapackage_path(@metapackage)
      return
    end
    card_editor(@package.name,@package.base_packages,session,current_user)
  end
  
  def remove_package
    if !check_owner(Metacontent.find(params[:package_id]).metapackage,current_user) then
      redirect_to :controller => :metapackages, :action => :edit, :id => params[:id]
      return
    end
    if Metacontent.delete(params[:package_id]).nil?
      flash[:error] = t(:controller_metapackages_11)
    end
    redirect_to :controller => :metapackages, :action => :edit, :id => params[:id]
  end
  
  def edit_action
    action = params[:method]
    meta   = Metapackage.find(params[:id])
    if !check_owner(meta,current_user) then
      redirect_to metapackage_path(meta)
      return
    end
    if not meta.nil?
        if action == "edit"
            redirect_to metapackage_path(meta) + "/edit"
        elsif action == "pedit"
            edit_packages
        elsif action == "publish"
          if current_user.anonymous? then
            flash[:error] = t(:controller_application_0)
            redirect_to root_path
          else
            meta.published = 1
            meta.modified = true
            meta.save!
            redirect_to metapackage_path(meta)
          end
        elsif action == "delete"
            if !meta.is_published?
              meta.destroy
            end
            redirect_to (user_path(current_user) + "/metapackages/0")
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
    @backlink        = session[:backlink]
    
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
