ActionController::Routing::Routes.draw do |map|

  map.resources :metapackages

  map.connect '/metapackages/:id/publish', :controller => "metapackages", :action => "publish", :method => :put
  map.connect '/metapackages/:id/unpublish', :controller => "metapackages", :action => "unpublish", :method => :put
  
  map.resources :categories
  
  map.resources :users, :member => { :enable => :put } do |users|
    users.resource  :user_profile
    users.resource  :account
    users.resources :roles
  end
  
  map.connect '/users/:distribution_id/suggestion', :controller => 'suggestion', :action => 'show'
  map.connect '/users/:id/suggestion/install', :controller => 'suggestion', :action => 'install'
  map.connect '/users/:user_id/metapackages/:id', :controller => 'users', :action => 'metapackages'

  map.connect '/users/:id/cart/:action/:id', :controller => 'cart'
  
  map.resources :distributions do |dist|
    dist.resources :metapackages
    dist.resources :packages  
    dist.resources :repositories
  end
  
  map.connect '/distributions/:id/packages/section', :controller => "packages", :action => "section", :method => :post
  map.connect '/distributions/:id/packages/search', :controller => "packages", :action => "search", :method => :post
    
  map.resource :session
  map.resource :password

  map.root :controller => 'home', :action => 'home'
  map.connect '/home',  :controller => 'home', :action => 'home'
  map.connect '/about', :controller => 'home', :action => 'about'
  map.connect '/admin/load_packages', :controller => 'admins', :action => 'load_packages'
  map.connect '/admin/sync_package/:id', :controller => 'admins', :action => 'sync_package'
  map.connect '/admin/repositories', :controller => 'repositories', :action => 'new'
  map.connect '/distributions', :controller => 'distributions', :action => 'index'


  map.activate '/activate/:id', :controller => 'accounts', :action => 'show'
  map.forgot_password '/forgot_password', :controller => 'passwords', :action => 'new'
  map.reset_password '/reset_password/:id', :controller => 'passwords', :action => 'edit'
  map.change_password '/change_password', :controller => 'accounts', :action => 'edit'
  map.signup '/signup', :controller => 'users', :action => 'new'
  map.login '/login', :controller => 'sessions', :action => 'new'
  map.logout '/logout', :controller => 'sessions', :action => 'destroy'
  map.categories '/categories', :controller => 'categories', :action => 'new' 
  map.admin '/admin', :controller => 'admin' 
  
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
  
end
