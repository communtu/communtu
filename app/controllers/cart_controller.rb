class CartController < ApplicationController
    
    def create
        if not editing_metapackage?
            session[:cart] = Cart.new
        end
        redirect_to "/users/" + current_user.id.to_s + "/metapackages/0"
    end
    
    def save
        if editing_metapackage?
            cart = session[:cart]
            meta = Metapackage.new
            meta.name            = cart.name
            meta.user_id         = current_user.id
            meta.distribution_id = current_user.distribution_id
            meta.category_id     = 1
            meta.description     = ""
            meta.rating          = 0
            meta.save!
            
            license = 0
            cart.content.each do |package|
                content = Metacontent.new
                content.metapackage_id  = meta.id
                content.base_package_id = package.id
                content.save!
                
                if package.type == Package
                    #lic = package.repository.license_type
                    #license = lic if lic > license
                else 
                    #lic = package.license_type
                    #license = lic if lic > license
                end
            end
            
            meta.update_attributes({:license_type => license})
            session[:cart] = nil
        end
        redirect_to "/distributions/" + current_user.distribution_id.to_s + "/metapackages/" \
            + meta.id.to_s + "/edit"
    end
    
    def clear
        if editing_metapackage?
            cart = session[:cart]
            cart.clear
        end
        render_cart
    end
    
    def add_to_cart
        if editing_metapackage?
            package = BasePackage.find(params[:id])
            session[:cart].add_to_cart(package)
        end
        render_cart
    end
        
    def rem_from_cart
        if editing_metapackage?
            package = BasePackage.find(params[:id])
            session[:cart].rem_from_cart(package)
        end
        render_cart
    end
    
    def render_cart
        respond_to do |wants|
            wants.js { render :partial => 'metacart.html.erb'}
        end
  end
    
end
