ActionController::Routing::Routes.draw do |map|
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
  map.resources :metapackages, :collection => {:save => :get, :immediate_conflicts => :get, :conflicts => :get,
                                               :rdepends => :get, :action => :get, :changed => :get, :migrate => :get,
                                               :finish_migrate => :get, :health_status => :get, :edit_new_or_cart => :get}
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

  map.connect '/user_profiles/create_livecd/:id', :controller => 'user_profiles', :action => 'create_livecd'
  map.connect '/user_profiles/test_livecd/:id', :controller => 'user_profiles', :action => 'test_livecd'

  map.connect '/users/anonymous_login', :controller => 'users', :action => 'anonymous_login'
  map.resources :users, :member => { :enable => :put, :anonymous_login => :get} do |users|
    users.resource  :user_profile
    users.resource  :account
    users.resources :roles
  end


  # URLs should be adpated to controllers
  map.connect '/users/:distribution_id/suggestion', :controller => 'suggestion', :action => 'show'
  map.connect '/users/:id/suggestion/install', :controller => 'suggestion', :action => 'install'
  map.connect '/users/:id/suggestion/install_new', :controller => 'suggestion', :action => 'install_new'
  map.connect '/users/:id/suggestion/install_sources', :controller => 'suggestion', :action => 'install_sources'
  map.connect '/users/:id/suggestion/install_package_sources/:pid', :controller => 'suggestion', :action => 'install_package_sources'
  map.connect '/users/:id/suggestion/install_bundle_sources/:mid', :controller => 'suggestion', :action => 'install_bundle_sources'
  map.connect '/users/:id/suggestion/bundle_to_livecd/:mid', :controller => 'suggestion', :action => 'bundle_to_livecd'
  map.connect '/users/:id/suggestion/quick_install/:mid', :controller => 'suggestion', :action => 'quick_install'
  map.connect '/users/:id/suggestion/shownew', :controller => 'suggestion', :action => 'shownew'
  map.connect '/users/:user_id/metapackages/:id', :controller => 'users', :action => 'metapackages'
  map.connect '/users/:user_id/user_profile/edit', :controller => 'user_profiles', :action => 'edit'
  map.connect '/users/:user_id/user_profile/installation', :controller => 'user_profiles', :action => 'installation'
  map.connect '/users/:user_id/user_profile/update_data', :controller => 'user_profiles', :action => 'update_data'
  map.connect '/users/:user_id/user_profile/update_ratings', :controller => 'user_profiles', :action => 'update_ratings'  
  map.connect '/users/:user_id/user_profile/settings', :controller => 'user_profiles', :action => 'settings'
  map.connect '/users/:user_id/user_profile/sources', :controller => 'user_profiles', :action => 'sources'
  map.connect '/users/:user_id/user_profile/livecd', :controller => 'user_profiles', :action => 'livecd'
  map.connect '/users/:user_id/user_profile/bundle_to_livecd/:id', :controller => 'user_profiles', :action => 'bundle_to_livecd'
  map.connect '/users/:user_id/user_profile/create_livecd_from_bundle/:id', :controller => 'user_profiles', :action => 'create_livecd_from_bundle'
  map.connect '/users/:id/destroy', :controller => 'users', :action => 'destroy'
  map.connect '/users/:id/show', :controller => 'users', :action => 'show'
  map.connect '/users/:id/cart/:action/:id', :controller => 'cart'

  # from authenticated plugin
  map.activate '/activate/:id', :controller => 'accounts', :action => 'show'
  map.forgot_password '/forgot_password', :controller => 'passwords', :action => 'new'
  map.reset_password '/reset_password/:id', :controller => 'passwords', :action => 'edit'
  map.change_password '/change_password', :controller => 'accounts', :action => 'edit'
  map.signup '/signup', :controller => 'users', :action => 'new'
  map.login '/login', :controller => 'sessions', :action => 'new'
  map.logout '/logout', :controller => 'sessions', :action => 'destroy'
  map.admin '/admin', :controller => 'admin'
  map.inbox '/inbox', :controller => "mailbox", :action => "show"

  # default rules
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
  
end
