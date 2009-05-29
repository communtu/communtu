module AuthenticatedSystem
  protected
    # Returns true or false if the user is logged in.
    # Preloads @current_user with the user model if they're logged in.
    def logged_in?
      current_user != :false
    end
 
    # Accesses the current user from the session.  Set it to :false if login fails
    # so that future calls do not hit the database.
    def current_user
      @current_user ||= (login_from_session || login_from_basic_auth || login_from_cookie || :false)
    end
     
    # Store the given user id in the session.
    def current_user=(new_user)
      session[:user_id] = (new_user.nil? || new_user.is_a?(Symbol)) ? nil : new_user.id
      @current_user = new_user || :false
    end
 
    # Check if the user is authorized
    #
    # Override this method in your controllers if you want to restrict access
    # to only a few actions or if you want to check if the user
    # has the correct rights.
    #
    # Example:
    #
    #  # only allow nonbobs
    #  def authorized?
    #    current_user.login != "bob"
    #  end
    def authorized?
      logged_in?
    end
 
    # Filter method to enforce a login requirement.
    #
    # To require logins for all actions, use this in your controllers:
    #
    #   before_filter :login_required
    #
    # To require logins for specific actions, use this in your controllers:
    #
    #   before_filter :login_required, :only => [ :edit, :update ]
    #
    # To skip this in a subclassed controller:
    #
    #   skip_before_filter :login_required
    #
    def login_required
      authorized? || access_denied
    end
    
    def not_logged_in_required
      !logged_in? || permission_denied
    end
    
    def check_role(role)
      unless logged_in? && @current_user.has_role?(role)
        if logged_in?
          permission_denied
        else
          access_denied
        end
      end
    end
 
    def check_administrator_role
      check_role('administrator')
    end    
 
    # Redirect as appropriate when an access request fails.
    #
    # The default action is to redirect to the login screen.
    #
    # Override this method in your controllers if you want to have special
    # behavior in case the user is not authorized
    # to access the requested action.  For example, a popup window might
    # simply close itself.
    def access_denied
      respond_to do |format|
        format.html do
          store_location
          flash[:error] = t(:message_0, :scope => [:txt, :lib, :system])
          redirect_to :controller => '/session', :action => 'new'
        end
        format.xml do
          request_http_basic_authentication 'Web Password'
        end
      end
    end
    
    def permission_denied
      respond_to do |format|
        format.html do
          store_location
          flash[:error] = t(:message_1, :scope => [:txt, :lib, :system])
          domain = t(:message_2, :scope => [:txt, :lib, :system]) #modify for your application settings
          http_referer = request.env["HTTP_REFERER"]
          request_path = request.env["REQUEST_PATH"]
          if request_path.nil? then request_path = "" end
          full_path = domain + request_path
          if http_referer.nil? || full_path.nil?
            redirect_to root_path
          else
            #Another area that needs to be modified for your app
            #The [0..20] represents the 21 characters in http://localhost:3000
            #You have to set that to the number of characters in your domain name
            if (http_referer[0..21] == domain) && (http_referer != full_path)
              redirect_to http_referer
            else
              redirect_to root_path
            end
          end
        end
        format.xml do
          headers["Status"]           = "Unauthorized"
          headers["WWW-Authenticate"] = %(Basic realm="Web Password")
          render :text => t(:message_3, :scope => [:txt, :lib, :system]), :status => '401 Unauthorized'
        end
      end
    end
 
    # Store the URI of the current request in the session.
    #
    # We can return to this location by calling #redirect_back_or_default.
    def store_location
      session[:return_to] = request.request_uri
    end
 
    # Redirect to the URI stored by the most recent store_location call or
    # to the passed default.
    def redirect_back_or_default(default)
      redirect_to(session[:return_to] || default)
      session[:return_to] = nil
    end
 
    # Inclusion hook to make #current_user and #logged_in?
    # available as ActionView helper methods.
    def self.included(base)
      base.send :helper_method, :current_user, :logged_in?
    end
 
    # Called from #current_user.  First attempt to login by the user id stored in the session.
    def login_from_session
      self.current_user = User.find(session[:user_id]) if session[:user_id]
    end
 
    # Called from #current_user.  Now, attempt to login by basic authentication information.
    def login_from_basic_auth
      authenticate_with_http_basic do |username, password|
        self.current_user = User.authenticate(username, password)
      end
    end
 
    # Called from #current_user.  Finaly, attempt to login by an expiring token in the cookie.
    def login_from_cookie
      user = cookies[:auth_token] && User.find_by_remember_token(cookies[:auth_token])
      if user && user.remember_token?
        user.remember_me
        cookies[:auth_token] = { :value => user.remember_token, :expires => user.remember_token_expires_at }
        self.current_user = user
      end
    end
end
