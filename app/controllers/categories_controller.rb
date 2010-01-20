class CategoriesController < ApplicationController
  def title
    t(:controller_categories_0)
  end
  before_filter :check_administrator_role, :add_flash => { :notice => I18n.t(:no_admin) }
  
  # GET /categories
  # GET /categories.xml
  def index
    @categories = Category.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @categories }
    end
  end

  # GET /categories/1
  # GET /categories/1.xml
  def show
    @category = Category.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @category }
    end
  end

  # GET /categories/new
  # GET /categories/new.xml
  def new
    @category = Category.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @category }
    end
  end

  # GET /categories/1/edit
  def edit
    @category = Category.find(params[:id])
  end

  # POST /categories
  # POST /categories.xml
  def create
    @category = Category.new(params[:category])
    @translation1 = Translation.new
    @translation2 = Translation.new
    @translation3 = Translation.new
    @last_trans = Translation.find(:first, :order => "translatable_id DESC")
    last_id = @last_trans.translatable_id
    @translation1.translatable_id = last_id + 1
    @translation1.contents = params[:category][:name]
    @translation2.translatable_id = last_id + 2
    @translation2.contents = params[:category][:description]
    @translation3.translatable_id = last_id + 3
    @translation3.contents = params[:category][:link]
    @category.description_tid = last_id + 1
    @category.name_tid = last_id + 1
    @translation1.language_code = I18n.locale.to_s
    @translation1.save
    if @translation2.contents != ""
      @category.description_tid = last_id + 2
      @translation2.language_code = I18n.locale.to_s
      @translation2.save
    end
       if @translation3.contents != ""
      @category.link_tid = last_id + 3
      @translation3.language_code = I18n.locale.to_s
      @translation3.save
    end

    respond_to do |format|
      if @category.save
        flash[:notice] = t(:controller_categories_2)
        format.html { redirect_to(@category) }
        format.xml  { render :xml => @category, :status => :created, :location => @category }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @category.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /categories/1
  # PUT /categories/1.xml
  def update
    @category = Category.find(params[:id])
    @trans_update_cat_title = Translation.find(:first, :conditions => { :translatable_id => @category.name_tid, :language_code => I18n.locale.to_s})
    if @trans_update_cat_title == nil
      @trans_update_cat_title = Translation.new
      @trans_update_cat_title.translatable_id = @category.name_tid
      @trans_update_cat_title.contents = params[:category][:name]
      @trans_update_cat_title.language_code = I18n.locale.to_s
    else
      @trans_update_cat_title.contents = params[:category][:name]
    end
    @trans_update_cat_title.save
    @trans_update_cat_des = Translation.find(:first, :conditions => { :translatable_id => @category.description_tid, :language_code => I18n.locale.to_s})
    if @trans_update_cat_des == nil
      @trans_update_cat_des = Translation.new
      @trans_update_cat_des.translatable_id = @category.description_tid
      @trans_update_cat_des.contents = params[:category][:description]
      @trans_update_cat_des.language_code = I18n.locale.to_s
    else
      @trans_update_cat_des.contents = params[:category][:description]
    end
    @trans_update_cat_des.save
    @trans_update_cat_link = Translation.find(:first, :conditions =>
        { :translatable_id => @category.link_tid, :language_code => I18n.locale.to_s})
    if @trans_update_cat_link == nil
      @trans_update_cat_link = Translation.new
      @trans_update_cat_link.translatable_id = @category.link_tid
      @trans_update_cat_link.contents = params[:category][:link]
      @trans_update_cat_link.language_code = I18n.locale.to_s
    else
      @trans_update_cat_link.contents = params[:category][:link]
    end
    @trans_update_cat_link.save
    respond_to do |format|
      if @category.update_attributes(params[:category])
        flash[:notice] = t(:controller_categories_3)
        format.html { redirect_to(@category) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @category.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /categories/1
  # DELETE /categories/1.xml
  def destroy
    @category = Category.find(params[:id])
    @translation_link = Translation.find(:all, :conditions => { :translatable_id => @category.link_tid })
    m = @translation_link.length
    e = 0
    m.times do
     @translation_link[e].delete
     e = e + 1
    end
    @translation_name = Translation.find(:all, :conditions => { :translatable_id => @category.name_tid })
    m = @translation_name.length
    e = 0
    m.times do
     @translation_name[e].delete
     e = e + 1
    end
    @translation_des = Translation.find(:all, :conditions => { :translatable_id => @category.description_tid })
    m = @translation_des.length
    e = 0
    m.times do
     @translation_des[e].delete
     e = e + 1
    end
    @category.delete

    respond_to do |format|
      format.html { redirect_to(categories_url) }
      format.xml  { head :ok }
    end
  end
  
  def show_tree
    Category.draw_tree
    system "dot -Tpng categories.dot > public/images/categories.png"
  end
end
