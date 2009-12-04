# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def is_admin?
    logged_in? and current_user.has_role?('administrator') 
  end
  
  def is_power_user?
    is_admin? or (logged_in? and current_user.has_role?('power user'))
  end

  def new_trans_id
    @last_trans = Translation.find(:first, :order => "translatable_id DESC")
    last_id = @last_trans.translatable_id
    return last_id + 1
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

  def package_link name
    link_to name, package_url(Package.find(:first,:conditions =>{:name => name.downcase}))
  end
  
  # show dependencies of a bundle or a package in structured form
  def show_rdependencies deps
    out = []
    show_rdependencies_aux deps, out
    return out.join("\n")
  end

  def show_rdependencies_aux deps, out
    out.push "<ul>"
    deps.each do |p,deps_local|
      out.push "<li>"
      meta = if p.class == Package then "" else "meta" end
      out.push "<a href=\"/#{meta}packages/#{p.id}\">#{p.name}</a>"
      show_rdependencies_aux deps_local, out 
      out.push "</li>"
    end
    out.push "</ul>"
  end

  def new_message?
    !current_user.received_messages.find(:first, :conditions=>["is_read = ?", false]).nil?
  end
  
  def received_messages?
    !current_user.received_messages.find(:first).nil?
  end
  
  def sent_messages?
    !current_user.sent_messages.find(:first).nil?
  end

  def is_gnome?
    !logged_in? or current_user.derivative.name=="Ubuntu"
  end

  def is_kde?
    logged_in? and current_user.derivative.name=="Kubuntu"
  end

  def is_xfce?
    logged_in? and current_user.derivative.name=="Xubuntu"
  end

  def locale_datetime(date_time)
    if I18n.locale.to_s == "de"
      date_time.strftime("%d.%m.%Y, %H:%M:%S Uhr")
    else
      date_time.strftime("%d.%m.%Y, %H:%M:%S")
    end
  end
  
end
