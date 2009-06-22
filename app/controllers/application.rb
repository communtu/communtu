# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  def available_locales; AVAILABLE_LOCALES; end 
  
    before_filter :set_locale

  def set_locale
    I18n.locale = extract_locale_from_subdomain
  end

  def extract_locale_from_subdomain
    parsed_locale = request.subdomains.second
    (AVAILABLE_LOCALES.include? parsed_locale) ? parsed_locale : nil
  end
  require 'set.rb'
  
  helper :all # include all helpers, all the time
  include AuthenticatedSystem
  include ApplicationHelper
  include TabzHelper
  
  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '0b1deaf6bf7e9a53ea11187cd1bbe6a1'
  
  rescue_from ActionController::InvalidAuthenticityToken, :with => :auth_error
  
  def auth_error
    redirect_to(:controller => 'home', :action => 'auth_error')
  end
  filter_parameter_logging :password 
  
  def is_anonymous 
    if current_user.anonymous?
      flash[:error] = t(:controller_application_0)
      redirect_to root_path
    end
  end
  
#  def default_url_options(options={})
#    logger.debug "default_url_options is passed options: #{options.inspect}\n"
#    { :locale => I18n.locale }
#  end
#  before_filter :set_locale
#  def set_locale
    ## if params[:locale] is nil then I18n.default_locale will be used
#    I18n.locale = params[:locale]
#  end
end
