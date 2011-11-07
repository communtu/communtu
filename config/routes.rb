Communtu::Application.routes.draw do
  resources :infos do
    collection do
  get :rss
  end


  end

  match '/' => 'home#home'
  resources :architectures
  resources :articles
  resources :categories do
    collection do
  get :show_tree
  end


  end

  match '/debs/bundle/:id' => 'debs#bundle'
  match '/debs/generate_bundle/:id' => 'debs#generate_bundle'
  resources :debs
  resources :derivatives do
    collection do
  get :migrate
  end


  end

  match '/distributions/migrate/:id' => 'distributions#migrate'
  match '/distributions/migrate_bundels/:id' => 'distributions#migrate_bundles'
  match '/distributions/make_visible/:id' => 'distributions#make_visible'
  match '/distributions/make_final/:id' => 'distributions#make_final'
  resources :distributions do


      resources :metapackages
    resources :packages
    resources :repositories
  end

  match '/home' => 'home#home'
  match '/faq' => 'home#faq'
  match '/mail/:navi' => 'home#mail'
  match '/about' => 'home#about'
  match '/contact_us' => 'home#contact_us'
  match '/cancel' => 'home#cancel'
  match '/success' => 'home#success'
  match '/users/spam_users_delete' => 'users#spam_users_delete'
  resources :livecds do

    member do
  get :stop_vm
  put :download
  get :remaster
  get :force_remaster
  get :remaster_new
  get :start_vm
  end

  end

  match '/metapackages/:id/publish' => 'metapackages#publish', :method => :put
  match '/metapackages/:id/unpublish' => 'metapackages#unpublish', :method => :put
  match '/metapackages/:id/edit_packages' => 'metapackages#edit_packages', :method => :put
  match '/metapackages/:id/edit_action' => 'metapackages#edit_action'
  match '/metapackages/install/:id' => 'metapackages#install'
  match '/metapackages/compute_conflicts/:id' => 'metapackages#compute_conflicts'
  match '/metapackages/new' => 'cart#create'
  resources :metapackages do
    collection do
  get :new_from_cart
  get :finish_migrate
  get :install_current
  get :health_status
  get :migrate
  get :action
  get :install_current_source
  get :edit_new_or_cart
  get :install_current_bundle
  get :immediate_conflicts
  get :save
  get :index_mine
  get :conflicts
  get :rdepends
  get :bundle_from_selection
  get :index
  get :changed
  end


  end

  resources :messages do

    member do
  get :forward
  get :reply
  end

  end

  resources :packages do
    collection do
  get :install_current
  get :packagelist
  get :install_current_source
  get :bundle
  get :section
  get :search
  get :install_current_package
  get :rdepends
  end


  end

  match '/bundle' => 'packages#bundle'
  resource :password
  match '/rating/rate' => 'rating#rate'
  resources :repositories
  resources :searches
  resources :sections
  resource :session
  resources :sent
  resources :mailbox
  resources :videos
  match '/download/create_livecd/:id' => 'download#create_livecd'
  match '/download/test_livecd/:id' => 'download#test_livecd'
  match '/download/bundle_to_livecd' => 'download#bundle_to_livecd'
  match '/users/anonymous_login' => 'users#anonymous_login'
  resources :users do

    member do
  put :search
  put :enable
  get :anonymous_login
  end
      resource :account
    resources :roles
  end

  match '/users/:id/destroy' => 'users#destroy'
  match '/users/:id/selfdestroy' => 'users#selfdestroy'
  match '/users/:id/show' => 'users#show'
  match '/activate/:id' => 'accounts#show', :as => :activate
  match '/forgot_password' => 'passwords#new', :as => :forgot_password
  match '/reset_password/:id' => 'passwords#edit', :as => :reset_password
  match '/change_password' => 'accounts#edit', :as => :change_password
  match '/signup' => 'users#new', :as => :signup
  match '/login' => 'sessions#new', :as => :login
  match '/logout' => 'sessions#destroy', :as => :logout
  match '/logout_login' => 'sessions#destroy', :as => :logout_login
  match '/admin' => 'admin#index', :as => :admin
  match '/inbox' => 'mailbox#show', :as => :inbox
  match '/:controller(/:action(/:id))'
end


#ActionController::Routing::Routes.draw do |map|
#  map.resources :infos, :collection => {:rss => :get}
#
#  map.root :controller => 'home', :action => 'home'
#
#  map.resources :architectures
#  map.resources :articles
#  map.resources :categories, :collection => {:show_tree => :get}
#  map.connect '/debs/bundle/:id', :controller => 'debs', :action => 'bundle'
#  map.connect '/debs/generate_bundle/:id', :controller => 'debs', :action => 'generate_bundle'
#  map.resources :debs, :collections => {:generate => :get, :generate_all =>:get}
#  map.resources :derivatives, :collection => {:migrate => :get}
#  map.connect '/distributions/migrate/:id', :controller => 'distributions', :action => 'migrate'
#  map.connect '/distributions/migrate_bundels/:id', :controller => 'distributions', :action => 'migrate_bundles'
#  map.connect '/distributions/make_visible/:id', :controller => 'distributions', :action => 'make_visible'
#  map.connect '/distributions/make_final/:id', :controller => 'distributions', :action => 'make_final'
#  map.resources :distributions do |dist|
#    dist.resources :metapackages
#    dist.resources :packages
#    dist.resources :repositories
#  end
#
#  # home controller
#  map.connect '/home',  :controller => 'home', :action => 'home'
#  map.connect '/faq', :controller => 'home', :action => 'faq'
#  map.connect '/mail/:navi', :controller => 'home', :action => 'mail'
#  map.connect '/about', :controller => 'home', :action => 'about'
#  map.connect '/contact_us', :controller => 'home', :action => 'contact_us'
#  map.connect '/cancel', :controller => 'home', :action => 'cancel'
#  map.connect '/success', :controller => 'home', :action => 'success'
#  map.connect '/users/spam_users_delete', :controller => 'users', :action => 'spam_users_delete'
#
#  map.resources :livecds, :member => { :remaster => :get, :force_remaster => :get, :remaster_new => :get, :start_vm => :get, :stop_vm => :get, :download => :put }
#  map.connect '/metapackages/:id/publish', :controller => "metapackages", :action => "publish", :method => :put
#  map.connect '/metapackages/:id/unpublish', :controller => "metapackages", :action => "unpublish", :method => :put
#  map.connect '/metapackages/:id/edit_packages', :controller => "metapackages", :action => "edit_packages", :method => :put
#  map.connect '/metapackages/:id/edit_action', :controller => 'metapackages', :action => 'edit_action'
#  map.connect '/metapackages/install/:id', :controller => 'metapackages', :action => 'install'
#  map.connect '/metapackages/compute_conflicts/:id', :controller => 'metapackages', :action => 'compute_conflicts'
#  map.connect '/metapackages/new', :controller => 'cart', :action => 'create'
#  map.resources :metapackages, :collection => {:save => :get, :immediate_conflicts => :get, :conflicts => :get,
#                                               :rdepends => :get, :action => :get, :changed => :get, :migrate => :get,
#                                               :finish_migrate => :get, :health_status => :get, :edit_new_or_cart => :get,
#                                               :index => :get, :index_mine => :get, :bundle_from_selection => :get,
#                                               :new_from_cart => :get, :install_current => :get, :install_current_source => :get,
#                                               :install_current_bundle => :get}
#  map.resources :messages, :member => { :reply => :get, :forward => :get }
#  map.resources :packages, :collection => {:packagelist => :get, :rdepends => :get, :search => :get, :section => :get, :bundle => :get, :install_current => :get, :install_current_source => :get,
#                                               :install_current_package => :get}
#  map.connect '/bundle', :controller => 'packages', :action => 'bundle'
#  map.resource :password
#  map.connect '/rating/rate', :controller => 'rating', :action => 'rate'
#  map.resources :repositories
#  map.resources :searches
#  map.resources :sections
#  map.resource :session
#  map.resources :sent, :mailbox
#  map.resources :videos
#
#  map.connect '/download/create_livecd/:id', :controller => 'download', :action => 'create_livecd'
#  map.connect '/download/test_livecd/:id', :controller => 'download', :action => 'test_livecd'
#  map.connect '/download/bundle_to_livecd', :controller => 'download', :action => 'bundle_to_livecd'
#
#  map.connect '/users/anonymous_login', :controller => 'users', :action => 'anonymous_login'
#  map.resources :users, :member => { :enable => :put, :search => :put, :anonymous_login => :get} do |users|
#    users.resource  :account
#    users.resources :roles
#  end
#  map.connect '/users/:id/destroy', :controller => 'users', :action => 'destroy'
#  map.connect '/users/:id/selfdestroy', :controller => 'users', :action => 'selfdestroy'
#  map.connect '/users/:id/show', :controller => 'users', :action => 'show'
#
#  # from authenticated plugin
#  map.activate '/activate/:id', :controller => 'accounts', :action => 'show'
#  map.forgot_password '/forgot_password', :controller => 'passwords', :action => 'new'
#  map.reset_password '/reset_password/:id', :controller => 'passwords', :action => 'edit'
#  map.change_password '/change_password', :controller => 'accounts', :action => 'edit'
#  map.signup '/signup', :controller => 'users', :action => 'new'
#  map.login '/login', :controller => 'sessions', :action => 'new'
#  map.logout '/logout', :controller => 'sessions', :action => 'destroy'
#  map.logout_login '/logout_login', :controller => 'sessions', :action => 'destroy'
#  map.admin '/admin', :controller => 'admin'
#  map.inbox '/inbox', :controller => "mailbox", :action => "show"
#
#  # default rules
#  map.connect ':controller/:action/:id'
#  map.connect ':controller/:action/:id.:format'
#
#end
