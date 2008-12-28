# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def is_admin?
    logged_in? and current_user.has_role?('administrator') 
  end
  
  def is_priviliged?
    is_admin? or (logged_in? and current_user.has_role?('priviliged'))
  end
  
  def is_current_controller? name
    (controller.controller_name <=> name) == 0 
  end
  
  def authorize_user_subresource
    logged_in? and (params[:user_id] == current_user.id)
  end
  
  def on_user_page?
    (controller.controller_name == "users" or
     controller.controller_name == "user_profiles" or
     controller.controller_name == "suggestion")
  end
  
  def on_admin_page?
    is_current_controller? 'admins' or 
    is_current_controller? 'categories' or
    is_current_controller? 'distributions' or
    is_current_controller? 'categories'
  end
  
  def editing_metapackage?
    not session[:cart].nil?
  end
  
  def render_flash
    out = ""
    
    flash.each do |key, value|
      out << "<span id='" << key.to_s << "'>" << value << "</span><br/>"
    end
    
    "<div class='flash'>" << out << "</div>" if not out.empty?
  end
  
  def card_editor(name,packages,session,current_user)
    cart = Cart.new
    cart.name = name
    cart.save
    packages.each do |p|
      cart.base_packages << p
    end
    session[:cart] = cart.id
    redirect_to "/users/" + current_user.id.to_s + "/metapackages/2"    
  end
  
  def change_date_time(datum) 
    if datum.nil? then
      ""
    else
      datum.strftime("%d.%m.%Y %H:%M")
    end  
  end  

end
