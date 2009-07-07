class CartController < ApplicationController
  before_filter :login_required
    def title
    t(:bundle_editor)
    end
    def create
        prepare_create
        redirect_to "/users/" + current_user.id.to_s + "/metapackages/2"
    end

    def prepare_create
        if not editing_metapackage?
            cart      = Cart.new
            cart.name = t(:new_bundle)
            cart.save!
            
            session[:cart] = cart.id
        end
    end

    def new_from_list
        prepare_create
    end
        
    def create_from_list
        if session[:cart].nil? then prepare_create end
        if !params[:datei][:attachment].nil? and params[:datei][:attachment]!="" then
          cart    = Cart.find(session[:cart])
          err = ""
          metas = {}
          Metapackage.all.each do |m|
            metas[m.debian_name] = m
          end
          params[:datei][:attachment].read.split("\n").each do |n|
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
        end
        if !err.empty? then
          flash[:notice] = t(:controller_cart_2)+err
        end
        redirect_to "/users/" + current_user.id.to_s + "/metapackages/2"
    end

    
    def save
        if editing_metapackage?
        
            cart = Cart.find(session[:cart])
            meta = Metapackage.find(:first, :conditions => ["user_id = ? and name = ?", current_user.id, cart.name])

            if meta.nil?
                meta = Metapackage.new
                meta.name            = cart.name
                meta.user_id         = current_user.id
                meta.category_id     = 1
                meta.version         = "0.1"
                meta.description     = ""
                meta.default_install = false
                meta.license_type = 0
                meta.save!
            end
            
            license = 0
            security = 0
            # delete packages outside cart...
            meta.base_packages(force_reload=true).each do |p| 
              if !cart.base_packages.include?(p) then
                meta.base_packages(force_reload=true).delete(p)
              end  
            end
            # ... and insert packages from cart
            cart.base_packages.each do |package|
              if !meta.base_packages.include?(package) then
                content = Metacontent.new
                content.metapackage_id  = meta.id
                content.base_package_id = package.id
                content.save!
                # default: available in all derivatives
                Derivative.all.each do |d|
                  content.derivatives << d
                end
                if package.class == Package
                  # default: available in all distributions of the package
                  package.distributions.each do |d|
                    content.distributions << d
                  end
                  # compute license type
                  lic = package.repositories.map{|r| r.license_type}.max
                  license = lic if !lic.nil? and lic > license
                  # compute security type
                  sec = package.repositories.map{|r| r.security_type}.max
                  security = sec if !sec.nil? and sec > security
                else
                  # default: available in all distributions
                  Distribution.all.each do |d|
                    content.distributions << d
                  end
                  # compute license type
                  lic = package.license_type
                  license = lic if !lic.nil? and lic > license
                  # compute security type
                  sec = package.security_type
                  security = sec if !sec.nil? and sec > security
                end
              end  
            end
            
            meta.update_attributes({:license_type => license, :security_type => security})
            cart.destroy
            session[:cart] = nil
            redirect_to({:controller => 'metapackages', :action => 'edit', :id => meta.id})
        else
        redirect_to "/users/" + current_user.id.to_s + "/metapackages/2"
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
        
    def rem_from_cart
        if editing_metapackage?
            cart    = Cart.find(session[:cart])            
            content = CartContent.find(:first, :conditions => ["cart_id = ? and base_package_id = ?", cart.id, params[:id]])
            content.destroy
        end
        render_cart
    end
    
    def render_cart
        respond_to do |wants|
            wants.js { render :partial => 'metacart.html.erb' }
        end
  end
    
end
