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

class SentController < ApplicationController
  before_filter :is_anonymous
 
  def index
    @messages = current_user.sent_messages.find(:all, :limit=>10, :order => "created_at DESC")
  end

  def show
    @message = current_user.sent_messages.find(params[:id])
  end

  def new
    @message = current_user.sent_messages.build(params[:message])
    #Looks for User login (:mail_to) from URL and fills into inputbox
    !params[:mail_to].nil? ? @message.to = User.find(params[:mail_to]).login : nil
    session[:return_to] = request.env["HTTP_REFERER"]
  end
  
  def create
    if(!User.find(:all,:conditions=>["login = ? and anonymous = ?",params[:message]['to'],false]).empty?)
      if params[:subject].nil? or params[:subject].empty?
        flash[:error] = t(:controller_sent_0)
      end
      @message = current_user.sent_messages.build(params[:message])
    else
      flash[:error] = t(:controller_sent_1)
      redirect_to new_sent_path({:message=>params[:message]})
      return
    end
    
    if @message.save
      respond_to do |format|
        format.html do 
          #Clears the flash[:error] Message
          flash.delete(:error)
          flash[:notice] = t(:controller_sent_2)
          #Redirects to metapackages where message was sent if successful else to new message
          redirect_to  request.get? ? request.env["HTTP_REFERER"] : session[:return_to]
        end
      end
    else
      render :action => "new"
    end
  end
  
  def update_user_exists
    render :update do |page|
     
      if(User.find(:all,:conditions=>["login = ? and anonymous = ?",params[:message]['to'],false]).empty?)
        page.replace_html :user_exists, :partial => 'user_not_exists'
      else
        page.replace_html :user_exists, :partial => 'user_exists'
      end  
    end
  end
end

