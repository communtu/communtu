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

class SessionsController < ApplicationController
  def title
    t(:view_layouts_application_21)
  end
  layout 'application'
  before_filter :login_required, :only => :destroy
  
  # render new.rhtml
  def new
    if logged_in?
      flash[:error] = t(:controller_sessions_1)
      redirect_to "/home"
    end
    if cookies[:backlink] == ""
      cookies[:backlink] = request.env['HTTP_REFERER']
    end
  end
 
  def show
    redirect_to :action => 'new'
  end
  
  def create
    if logged_in?
      flash[:error] = t(:controller_sessions_1)
      redirect_to "/home"
      return
    end
    password_authentication(params[:login], params[:password])
    # check if distribution still exists
    if logged_in? and current_user.distribution.nil? then
      while current_user.distribution.nil?
        current_user.distribution_id += 1
        current_user.save
      end  
      flash[:error] = t(:controller_sessions_3,{:dist_old=>current_user.distribution.short_name,:dist_new=>current_user.distribution.name})
    end
  end
 
  def destroy
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    
    if editing_metapackage?
        Cart.find(session[:cart]).destroy
    end
    
    self.current_user.first_login = 0
    self.current_user.save!
    
    reset_session
	  if request.env['REQUEST_URI'] == "/logout_login"
	       redirect_to "/session/new"
	  else
 	       flash[:notice] = t(:controller_sessions_4)
	       redirect_to "/home"
	  end
  end
  
  protected
  
  # Updated 2/20/08
  def password_authentication(login, password)
    user = User.authenticate(login, password)
    if user == nil
      failed_login(t(:controller_sessions_5))
    elsif user.activated_at.blank?  
      failed_login(t(:controller_sessions_6))
    elsif user.enabled == false
      failed_login(t(:controller_sessions_7))
    else
      self.current_user = user
      if editing_metapackage?
        Cart.find(session[:cart]).destroy
      end
      successful_login
    end
  end
  
  private
  
  def failed_login(message)
    flash[:error] = message 
    @login = params[:login]
    render :action => 'new'
  end
  
  def successful_login
    if params[:remember_me] == "1"
      self.current_user.remember_me
      cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
    end
      t=Time.now()
      u = User.find(current_user.id)
      u.updated_at = t
      u.save
      return_to = session[:return_to]
      if return_to.nil?
        if self.current_user.first_login == 1
          if cookies[:backlink] != nil
          redirect_to cookies[:backlink]
          else
          redirect_to "/download/selection"
          end        
        else
          if cookies[:backlink] != nil
            redirect_to cookies[:backlink]
          else
           redirect_to "/home"
          end
        end
      else
        redirect_to return_to
      end
  end
 
end
