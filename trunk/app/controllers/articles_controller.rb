class ArticlesController < ApplicationController
  def title
    t(:view_layouts_application_21)
  end
  def new
    @article = Article.new
    respond_to do |format|
    format.html # new.html.erb
    format.xml  { render :xml => @article }
    end
  end 

  # GET /articles/1
  # GET /articles/1.xml
  def create
    @article = Article.new
    @translation1 = Translation.new   
    @translation2 = Translation.new  
    @translation3 = Translation.new  
    @last_trans = Translation.find(:first, :order => "translatable_id DESC")
    last_id = @last_trans.translatable_id
    @translation1.translatable_id = last_id + 1
    @translation1.contents = params[:article][:description]
    @translation2.translatable_id = last_id + 2
    @translation2.contents = params[:article][:url]
    @translation3.translatable_id = last_id + 3
    @translation3.contents = params[:article][:name]
    if @translation1.contents != ""
      @article.description_tid = last_id + 1
      @translation1.language_code = I18n.locale.to_s
      @translation1.save
    end
       if @translation2.contents != ""
      @article.url_tid = last_id + 2
      @translation2.language_code = I18n.locale.to_s
      @translation2.save
    end
       if @translation3.contents != ""
      @article.name_tid = last_id + 3
      @translation3.language_code = I18n.locale.to_s
      @translation3.save
    end
      @article.language_code = I18n.locale.to_s
      @article.save
    respond_to do |format|
   if @article.save   
       format.xml  { }        
   else
     format.html { render :action => "new" }
     format.xml  { render :xml => @article.errors, :status => :unprocessable_entity }
   end
   end  
    redirect_to "/articles"                                                                  
  end

  def index
    @articles = Article.find(:all, :conditions => {:language_code => I18n.locale.to_s}, :order => 'created_at DESC')
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @article }
    end
  end

  # GET /articles/1/edit
  def edit
    @article = Article.find(params[:id])
  end

  # PUT /articles/1
  # PUT /articles/1.xml
  def update
    @article = Article.find(params[:id])
    @trans_update_url = Translation.find(:first, :conditions => { :translatable_id => @article.url_tid, :language_code => I18n.locale.to_s})
    if @trans_update_url == nil
      @trans_update_url = Translation.new
      @trans_update_url.translatable_id = @article.url_tid
      @trans_update_url.contents = params[:article][:url]
      @trans_update_url.language_code = I18n.locale.to_s
    else
      @trans_update_url.contents = params[:article][:url]
    end
    @trans_update_url.save
    @trans_update_des = Translation.find(:first, :conditions => { :translatable_id => @article.description_tid, :language_code => I18n.locale.to_s})
    if @trans_update_des == nil
      @trans_update_des = Translation.new
      @trans_update_des.translatable_id = @article.description_tid
      @trans_update_des.contents = params[:article][:description]
      @trans_update_des.language_code = I18n.locale.to_s
    else
      @trans_update_des.contents = params[:article][:description]
    end
    @trans_update_des.save
      @trans_update_name = Translation.find(:first, :conditions => { :translatable_id => @article.name_tid, :language_code => I18n.locale.to_s})
    if @trans_update_name == nil
      @trans_update_name = Translation.new
      @trans_update_name.translatable_id = @article.name_tid
      @trans_update_name.contents = params[:article][:name]
      @trans_update_name.language_code = I18n.locale.to_s
    else
      @trans_update_name.contents = params[:article][:name]
    end
    @trans_update_name.save
    redirect_to "/articles"
  end

  # DELETE /articles/1
  # DELETE /articles/1.xml
  def destroy
    @article = Article.find(params[:id])
        @translation_url = Translation.find(:all, :conditions => { :translatable_id => @article.url_tid })
    m = @translation_url.length
    e = 0
    m.times do
     @translation_url[e].delete
     e = e + 1
    end
    @translation_des = Translation.find(:all, :conditions => { :translatable_id => @article.description_tid })
    m = @translation_des.length
    e = 0
    m.times do
     @translation_des[e].delete
     e = e + 1
    end
    @translation_name = Translation.find(:all, :conditions => { :translatable_id => @article.name_tid })
    m = @translation_name.length
    e = 0
    m.times do
     @translation_name[e].delete
     e = e + 1
    end
    @article.destroy

    respond_to do |format|
      format.html { redirect_to(articles_url) }
      format.xml  { head :ok }
    end
  end
end
