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

class CartController < ApplicationController
  before_filter :login_required, :except => :create
  
    def title
    t(:bundle_editor)
    end
    def create
        if !logged_in?
          do_anonymous_login(true)
        end
        prepare_create
        redirect_to "/packages"
    end

    def new_from_list
        prepare_create
    end
        
    def create_from_list
        prepare_create
        err = ""
        package_list = ""
        # read package list from file
        if !params[:file][:attachment].nil? and params[:file][:attachment]!="" then
          package_list += params[:file][:attachment].read
          package_list += " "
        end  
        # get package list from text area
        if !params[:package_list].nil? and params[:package_list]!="" then
          package_list += params[:package_list]
        end
        # get an array of packages
        package_list = package_list.gsub(/\n/," ").split(" ")
        if !package_list.empty?  
          cart = Cart.find(session[:cart])
          metas = {}
          Metapackage.all.each do |m|
            metas[m.debian_name] = m
          end
          package_list.each do |n|
            package = BasePackage.find(:first, :conditions => ["name = ?",n])
            if package.nil? then
              package = metas[n]
            end
            if package.nil? then
              err += n+" "
            else  
              content = CartContent.new
              content.cart_id         = cart.id
              content.base_package_id = package.id
              content.save!          
            end  
          end
        else
          flash[:error] = t(:error_no_packages)
        end
        if err != ""
          err=err.gsub("<","")
          err=err.gsub(">","")
          flash[:error] = t(:controller_cart_2, :message => err, :url => "/home/new_repository")
        end
        redirect_to "/packages" 
    end

    
    def save
     cart = Cart.find(session[:cart])
     if editing_metapackage?
       bundle_id = cart.metapackage_id
       if bundle_id.nil?
         redirect_to :controller => 'metapackages', :action => 'new_from_cart', :name => cart.name
       else
         redirect_to({:controller => 'metapackages', :action => 'edit_new_or_cart', :id => bundle_id})
       end
     else
       cart.destroy
       session[:cart] = nil
       redirect_to "/packages"
     end 
    end
    
    def clear
        if editing_metapackage?
            cart = Cart.find(session[:cart])
            cart.destroy
            session[:cart] = nil
        end
        render_cart
    end
    
    def add_to_cart
        if editing_metapackage?
            package = BasePackage.find(params[:id])
            cart    = Cart.find(session[:cart])
            
            content = CartContent.new
            content.cart_id         = cart.id
            content.base_package_id = package.id
            content.save!
        end
        render_cart
    end

    def add_to_cart_box
        if editing_metapackage?
            package = BasePackage.find(params[:id])
            cart    = Cart.find(session[:cart])
            
            content = CartContent.new
            content.cart_id         = cart.id
            content.base_package_id = package.id
            content.save!
        end
        render_cart_box
    end
        
    def rem_from_cart
        if editing_metapackage?
            cart    = Cart.find(session[:cart])            
            content = CartContent.find(:all, :conditions => ["cart_id = ? and base_package_id = ?", cart.id, params[:id]])
            content.each do |c| 
              if !c.nil? then c.destroy end 
            end
            #content = CartContent.find(:first, :conditions => ["cart_id = ? and base_package_id = ?", cart.id, params[:id]])
            #if !content.nil? then content.destroy end
        end
        render_cart
    end
    
    def render_cart
        respond_to do |wants|
            wants.js { render :partial => 'metacart.html.erb'}
        end
    end

    def render_cart_box
        respond_to do |wants|
            wants.js { render :partial => 'metacart_box.html.erb' }
        end
    end
    
end
