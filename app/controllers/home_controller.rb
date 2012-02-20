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
    @livecds = Livecd.find(:all, :order => "downloaded DESC", :limit => 5, :conditions => {:published => true,:failed => false})
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
  
  def news
      if params[:announce] == "1" and I18n.locale.to_s == "de"
         system "echo \"\" | mail -s \"announce\" -c info@toddy-franz.de -a \"FROM: #{current_user.email}\" communtu-announce-de+subscribe@googlegroups.com &"
         flash[:notice] = t(:thanks_for_order)
      elsif params[:announce] == "1"
         system "echo \"\" | mail -s \"announce\" -c info@toddy-franz.de -a \"FROM: #{current_user.email}\" communtu-announce-en+subscribe@googlegroups.com &"
         flash[:notice] = t(:thanks_for_order)
      end
      if params[:discuss] == "1" and I18n.locale.to_s == "de"
         system "echo \"\" | mail -s \"discuss\" -c info@toddy-franz.de -a \"FROM: #{current_user.email}\" communtu-discuss-de+subscribe@googlegroups.com &"
         flash[:notice] = t(:thanks_for_order)
      elsif params[:discuss] == "1"
         system "echo \"\" | mail -s \"discuss\" -c info@toddy-franz.de -a \"FROM: #{current_user.email}\" communtu-discuss-en+subscribe@googlegroups.com &"
         flash[:notice] = t(:thanks_for_order)
      end

      @infos = Info.find(:all, :conditions => ['created_at > ?', Date.today-365], :order => 'created_at DESC' )
  end

  def donate
  end
  
 def email
    @form_name = params[:form][:name]
    @form_frage = params[:form][:frage]
    u = if logged_in? then current_user else User.first end
    MyMailer.deliver_mail(@form_name, @form_frage, u)
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

  def search
    @word = params[:search]
    #@meta = Metapackage.find_all_by_published_and_description(1, '%'+@word+'%');
    @metas = Metapackage.find(:all, :conditions => ['published = ? AND translations.contents LIKE ? AND translations.language_code = ?', 1, '%'+@word+'%', I18n.locale.to_s], :include => "translations")
    @packages = Package.find(:all, :conditions => ['description LIKE ? ', '%'+@word+'%'])
    @livecds = Livecd.find(:all, :conditions => ['metapackage_id IN (?)', @metas.map(&:id).join(",")])
    #@livecds = Livecd.find(:all, :conditions => ['base_packages.published = ? AND translations.contents LIKE ? AND translations.language_code = ?', 1, '%'+@word+'%', I18n.locale.to_s], :include => [ "metapackage","translations"])
  end
end
