ActionController::Routing::Routes.draw do |map|
  
  map.resources :categories
  map.resources :metapackages
  
  map.connect '/metapackage/action', :controller => 'metapackages', :action => 'action'
  map.connect '/metapackage/changed', :controller => 'metapackages', :action => 'changed'
  map.connect '/metapackage/migrate', :controller => 'metapackages', :action => 'migrate'
  map.connect '/metapackage/finish_migrate', :controller => 'metapackages', :action => 'finish_migrate'
  
  map.resources :users, :member => { :enable => :put } do |users|
    users.resource  :user_profile
    users.resource  :account
    users.resources :roles
  end
  
  map.connect '/users/:distribution_id/suggestion', :controller => 'suggestion', :action => 'show'
  map.connect '/users/:id/suggestion/install', :controller => 'suggestion', :action => 'install'
  map.connect '/users/:user_id/metapackages/:id', :controller => 'users', :action => 'metapackages'
  map.connect '/users/:user_id/user_profile/tabs/:id', :controller => 'user_profiles', :action => 'edit'
  map.connect '/users/:user_id/user_profile/update_data', :controller => 'user_profiles', :action => 'update_data'
  map.connect '/users/:user_id/user_profile/update_rating', :controller => 'user_profiles', :action => 'update_rating'

  map.connect '/users/:id/cart/:action/:id', :controller => 'cart'
  
  map.resources :distributions do |dist|
    dist.resources :metapackages
    dist.resources :packages  
    dist.resources :repositories
  end
  
  map.connect '/distributions/:id/packages/section', :controller => "packages", :action => "section", :method => :post
  map.connect '/distributions/:id/packages/search', :controller => "packages", :action => "search", :method => :post
  map.connect '/distributions/:distribution_id/metapackages/:id/publish', :controller => "metapackages", :action => "publish", :method => :put
  map.connect '/distributions/:distribution_id/metapackages/:id/unpublish', :controller => "metapackages", :action => "unpublish", :method => :put
  map.connect '/distributions/:distribution_id/metapackages/:id/edit_packages', :controller => "metapackages", :action => "edit_packages", :method => :put
    
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
