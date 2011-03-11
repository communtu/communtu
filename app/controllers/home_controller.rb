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

class HomeController < ApplicationController
  
  def title
    if params[:action] == "impressum"
      "Communtu: " + t(:imprint)
    elsif params[:action] == "beteiligung"
      "Communtu: " + t(:participation)
    elsif params[:action] == "contact_us"
      "Communtu: " + t(:view_home_contact_us_0)
    elsif params[:action] == "news"
      "Communtu: " + t(:news)
    elsif params[:action] == "chat"
      "Communtu: " + t(:chat)
    elsif params[:action] == "about"
      "Communtu: " + t(:about_us)
    elsif params[:action] == "faq"
      "Communtu: " + t(:view_home_faq_00)
    elsif params[:action] == "donate"
      "Communtu: " + t(:view_home_donate)
    else
      t(:view_layouts_application_21)
    end 
  end
  protect_from_forgery :only => [:create, :update, :destroy] 
  
  def home
    @metapackges = Metapackage.find(:all,
      :select => "base_packages.*, avg(ratings.rating) AS rating",
      :joins => "LEFT JOIN ratings ON base_packages.id = ratings.rateable_id",
      :conditions => "ratings.rateable_type = 'BasePackage'",
      :group => "ratings.rateable_id HAVING COUNT(ratings.id) > 2",
      :order => "rating DESC",
      :limit => 5)
    @info = Info.find(:first, :conditions => ['created_at > ?', Date.today-14], :order => 'created_at DESC' )
    @livecds = Livecd.find(:all, :order => "downloaded DESC", :limit => 5, :conditions => "published = true")
  end
  
  def about
  end
  
  def derivatives
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

  def faq
    @faq = true
  end

end
