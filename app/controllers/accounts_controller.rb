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

class AccountsController < ApplicationController
  def title
    t(:view_layouts_application_21)
  end
  layout 'application'
  before_filter :login_required, :except => :show
  before_filter :not_logged_in_required, :only => :show
 
  # Activate action
  def show
    # Uncomment and change paths to have user logged in after activation - not recommended
    #self.current_user = User.find_and_activate!(params[:id])
  User.find_and_activate!(params[:id])
    flash[:notice] = t(:controller_accounts_1)
    redirect_to login_path
  rescue User::ArgumentError
    flash[:notice] = t(:controller_accounts_2)
    redirect_to new_user_path 
  rescue User::ActivationCodeNotFound
    flash[:notice] = t(:controller_accounts_2)
    redirect_to new_user_path
  rescue User::AlreadyActivated
    flash[:notice] = t(:controller_accounts_4)
    redirect_to login_path
  end
  
  # Change password action  
  def update
    
  return unless request.post?
    if User.authenticate(current_user.login, params[:old_password])
      if ((params[:password] == params[:password_confirmation]) && !params[:password_confirmation].blank?)
        current_user.password_confirmation= params[:password_confirmation]
        current_user.password= params[:password]        
        if current_user.save
          flash[:notice] = t(:controller_accounts_5)
          redirect_to root_path #profile_url(current_user.login)
        else
          flash[:error] = t(:controller_accounts_6)
          render :action => 'edit'
        end
      else
        flash[:error] = t(:passwd_no_match)
        @old_password = params[:old_password]
        render :action => 'edit'      
      end
    else
      flash[:error] = t(:controller_accounts_8)
      render :action => 'edit'
    end 
  end
  
end
