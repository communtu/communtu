ActionController::Routing::Routes.draw do |map|
  map.resources :infos, :collection => {:rss => :get}

  map.root :controller => 'home', :action => 'home'

  map.resources :architectures
  map.resources :articles
  map.resources :categories, :collection => {:show_tree => :get}
  map.connect '/debs/bundle/:id', :controller => 'debs', :action => 'bundle'
  map.connect '/debs/generate_bundle/:id', :controller => 'debs', :action => 'generate_bundle'
  map.resources :debs, :collections => {:generate => :get, :generate_all =>:get}
  map.resources :derivatives, :collection => {:migrate => :get}
  map.connect '/distributions/migrate/:id', :controller => 'distributions', :action => 'migrate'
  map.connect '/distributions/migrate_bundels/:id', :controller => 'distributions', :action => 'migrate_bundles'
  map.connect '/distributions/make_visible/:id', :controller => 'distributions', :action => 'make_visible'
  map.connect '/distributions/make_final/:id', :controller => 'distributions', :action => 'make_final'
  map.resources :distributions do |dist|
    dist.resources :metapackages
    dist.resources :packages
    dist.resources :repositories
  end

  # home controller
  map.connect '/home',  :controller => 'home', :action => 'home'
  map.connect '/faq', :controller => 'home', :action => 'faq'
  map.connect '/mail/:navi', :controller => 'home', :action => 'mail'
  map.connect '/about', :controller => 'home', :action => 'about'
  map.connect '/contact_us', :controller => 'home', :action => 'contact_us'
  map.connect '/cancel', :controller => 'home', :action => 'cancel'
  map.connect '/success', :controller => 'home', :action => 'success'
  map.connect '/users/spam_users_delete', :controller => 'users', :action => 'spam_users_delete'

  map.resources :livecds, :member => { :remaster => :get, :force_remaster => :get, :remaster_new => :get, :start_vm => :get, :stop_vm => :get }
  map.connect '/metapackages/:id/publish', :controller => "metapackages", :action => "publish", :method => :put
  map.connect '/metapackages/:id/unpublish', :controller => "metapackages", :action => "unpublish", :method => :put
  map.connect '/metapackages/:id/edit_packages', :controller => "metapackages", :action => "edit_packages", :method => :put
  map.connect '/metapackages/:id/edit_action', :controller => 'metapackages', :action => 'edit_action'
  map.connect '/metapackages/install/:id', :controller => 'metapackages', :action => 'install'
  map.connect '/metapackages/new', :controller => 'cart', :action => 'create'
  map.resources :metapackages, :collection => {:save => :get, :immediate_conflicts => :get, :conflicts => :get,
                                               :rdepends => :get, :action => :get, :changed => :get, :migrate => :get,
                                               :finish_migrate => :get, :health_status => :get, :edit_new_or_cart => :get, 
                                               :index => :get, :index_mine => :get, :bundle_from_selection => :get,
                                               :new_from_cart => :get}
  map.resources :messages, :member => { :reply => :get, :forward => :get }
  map.resources :packages, :collection => {:packagelist => :get, :rdepends => :get, :search => :get, :section => :get, :bundle => :get}
  map.connect '/bundle', :controller => 'packages', :action => 'bundle'
  map.resource :password
  map.connect '/rating/rate', :controller => 'rating', :action => 'rate'
  map.resources :repositories
  map.resources :searches
  map.resources :sections
  map.resource :session
  map.resources :sent, :mailbox
  map.resources :videos

  map.connect '/download/create_livecd/:id', :controller => 'download', :action => 'create_livecd'
  map.connect '/download/test_livecd/:id', :controller => 'download', :action => 'test_livecd'

  map.connect '/users/anonymous_login', :controller => 'users', :action => 'anonymous_login'
  map.resources :users, :member => { :enable => :put, :search => :put, :anonymous_login => :get} do |users|
    users.resource  :user_profile
    users.resource  :account
    users.resources :roles
  end
  map.connect '/users/:id/destroy', :controller => 'users', :action => 'destroy'
  map.connect '/users/:id/selfdestroy', :controller => 'users', :action => 'selfdestroy'
  map.connect '/users/:id/show', :controller => 'users', :action => 'show'

  # from authenticated plugin
  map.activate '/activate/:id', :controller => 'accounts', :action => 'show'
  map.forgot_password '/forgot_password', :controller => 'passwords', :action => 'new'
  map.reset_password '/reset_password/:id', :controller => 'passwords', :action => 'edit'
  map.change_password '/change_password', :controller => 'accounts', :action => 'edit'
  map.signup '/signup', :controller => 'users', :action => 'new'
  map.login '/login', :controller => 'sessions', :action => 'new'
  map.logout '/logout', :controller => 'sessions', :action => 'destroy'
  map.logout_login '/logout_login', :controller => 'sessions', :action => 'destroy'
  map.admin '/admin', :controller => 'admin'
  map.inbox '/inbox', :controller => "mailbox", :action => "show"

  # default rules
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
  
end
