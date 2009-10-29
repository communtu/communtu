class HomeController < ApplicationController
  
  def title
    t(:view_layouts_application_21)
  end
  protect_from_forgery :only => [:create, :update, :destroy] 
  
  def home
    @metapackges = Metapackage.find(:all,
      :select => "base_packages.*, avg(ratings.rating) AS rating",
      :joins => "LEFT JOIN ratings ON base_packages.id = ratings.rateable_id",
      :conditions => "ratings.rateable_type = 'BasePackage'",
      :group => "ratings.rateable_id",
      :order => "rating DESC",
      :limit => 5)
  end
  
  def about
  end
  
  def derivatives
  end

  def umfrage
  end

  def auth_error
  end
  
  def icons  
  end

  def mail
  end

  def donate
  end
  
 def email
     @form_name = params[:form][:name]
     @form_frage = params[:form][:frage]
     if logged_in?
     MyMailer.deliver_mail(@form_name, @form_frage, current_user)
     else
     u = User.find(3)
     current_user = u
     MyMailer.deliver_mail(@form_name, @form_frage, current_user)
     current_user = ""
     end
    flash[:notice] = t(:controller_home_1)
    redirect_to params[:form][:backlink]
  end

 def repo
     @form_name = params[:form][:name]
     @form_frage = params[:form][:frage]
     MyMailer.deliver_repo(@form_name, @form_frage, current_user)
     flash[:notice] = t(:controller_home_5)
     redirect_to '/home'
 end                           

  def submit_mail
    @form_email = params[:form][:email]
    MyMailer.deliver_mailerror(@form_email)
    flash[:notice] = t(:controller_home_2)
    redirect_to '/home'
  end

  def danke
    @u = Umfrage.find(params[:id])
  end

  def save_umfrage    
    flash[:notice] = ""
    flash[:error] = ""
    @u = Umfrage.new(params[:data])
    @u.save
    begin
      count = 0
      err_count = 0
      params[:attachment][:packages].read.split("\n").each do |n|
        UmfragePackage.create(:umfrage_id => @u.id,:package => n)
        count += 1
        if Package.find(:first,:conditions => ["name = ?",n]).nil? then
          err_count += 1
        end
      end
      read_packages = true
      if err_count*3 > count then
        read_packages = false
        flash[:error] = t(:controller_home_3)
      end
      begin
        params[:attachment][:sources].read.split("\n").each do |n|
           UmfrageSource.create(:umfrage_id => @u.id,:source => n)
        end   
      rescue
      end
    rescue
      flash[:error] = t(:controller_home_4)
      read_packages = false
    end
    if !read_packages then
       @u.destroy
       @u = nil
    end  
  end
end
