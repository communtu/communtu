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
     controller.controller_name == "download" or
     controller.controller_name == "suggestion")
  end
  
  def on_admin_page?
    is_current_controller? 'admins' or 
    is_current_controller? 'categories' or
    is_current_controller? 'distributions' or
    is_current_controller? 'categories'
  end
  
  def render_flash
    out = ""
    
    flash.each do |key, value|
      out << "<span id='" << key.to_s << "'>" << value << "</span><br/>"
    end
    
    "<div class='flash'>" << out << "</div>" if not out.empty?
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

  # need, cause a bundle which is in a bundle doesn't deleted by a user
  def is_in_bundle(metapackage)
    m = Metacontent.find(:first,:conditions => ["base_package_id = ?",metapackage.id])
    if m != nil
      return metapackage.id  
    else
      return "nix"    
    end 
  end

  ##############################
  # card editor methods
  ##############################

  def editing_metapackage?
    if !session[:cart].nil? 
      if Cart.find_by_id(session[:cart]).nil? # outdated cookie?
        session[:cart] = nil # then remove it
      end
    end
    return (not session[:cart].nil?)
  end

  def base_package_path(base_package)
    if base_package.class == Metapackage
      metapackage_path(base_package)
    else
      package_path(base_package)
    end
  end

  def card_editor(name,packages,session,current_user,meta_id=nil,delete_package = nil)
    cart = Cart.new
    cart.name = name
    cart.metapackage_id = meta_id
    cart.save
    packages.each do |p|
      if p.id != delete_package
        cart.base_packages << p
      end
    end
    session[:cart] = cart.id
    redirect_to "/packages"
  end

  # check cart contents (i.e. package selection for a bundle) for recursive dependencies
  def check_cart(meta)
    cart = Cart.find(session[:cart])
    metas = cart.base_packages.select{|p| p.class == Metapackage }
    Metapackage.close_deps(metas)
    return metas.include?(meta)
  end

  # save cart contents (i.e. package selection for a bundle) to database
  def save_cart(meta)
    cart = Cart.find(session[:cart])
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
    return meta
  end

  def check_bundle_name(name,bundle=nil)
    # compute debian names of existing metapackages, without "communtu-" oder "communtu-private-bundle-" prefix
    metanames = (Metapackage.all-[bundle]).map{|m| if m.name.nil? then "" else BasePackage.debianize_name(m.name) end}
    if name==t(:new_bundle) or metanames.include?(BasePackage.debianize_name(name)) then
      return false
    end
    return true
  end

  def check_english_bundle_name(name_english,bundle=nil)
    if name_english.nil?
      return false
    end
    # compute debian names of existing metapackages, without "communtu-" oder "communtu-private-bundle-" prefix
    metanames = (Metapackage.all-[bundle]).map{|m| if m.name_english.nil? then "" else BasePackage.debianize_name(m.name_english) end}
    if name_english==t(:new_bundle) or metanames.include?(BasePackage.debianize_name(name_english)) then
      return false
    end
    return true
  end

  def prepare_create
        if not editing_metapackage?
            cart      = Cart.new
            cart.name = t(:new_bundle)+"_"+current_user.login
            cart.save!
            
            session[:cart] = cart.id
        end
  end

end
