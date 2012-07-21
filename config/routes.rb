Communtu::Application.routes.draw do

  resource :session, :only => [:new, :create, :destroy]

  match 'signup' => 'users#new', :as => :signup

  match 'register' => 'users#create', :as => :register

  match 'login' => 'sessions#new', :as => :login

  match 'logout' => 'sessions#destroy', :as => :logout

  match '/activate/:activation_code' => 'users#activate', :as => :activate, :activation_code => nil

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'

  resources :infos do
    collection do
  get :rss
  end
  
  
  end

  root :to => 'home#home_new'
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
  resources :distributions

  match '/home' => 'home#home'
  match '/faq' => 'home#faq'
  match '/mail/:navi' => 'home#mail'
  match '/about' => 'home#about'
  match '/contact_us' => 'home#contact_us'
  match '/cancel' => 'home#cancel'
  match '/success' => 'home#success'
  resources :livecds do
  
    member do
      get :index
      get :show
      get :remaster
      get :force_remaster
      get :remaster_new
      put :download
      get :start_vm
      get :stop_vm
    end
  
  end

  match '/metapackages/index' => 'metapackages#index'
  match '/metapackages/install/:id' => 'metapackages#install'
  match '/metapackages/compute_conflicts/:id' => 'metapackages#compute_conflicts'
  match '/metapackages/new' => 'cart#create'
  match '/metapackages/selection_new' => 'metapackages#selection_new'
  resources :metapackages do
    collection do
      get :index_mine
      get :immediate_conflicts
      get :bundle_from_selection
      get :migrate
      get :rdepends
      get :new_from_cart
      get :finish_migrate
      get :action
      get :conflicts
      get :install_current
      get :health_status
      get :install_current_source
      get :save
      # get :index
      get :edit_new_or_cart
      get :changed
      get :install_current_bundle
      get :selection
    end
  end
  

  #match '/metapackages/:id/publish' => 'metapackages#publish', :method => :put
  #match '/metapackages/:id/unpublish' => 'metapackages#unpublish', :method => :put
  #match '/metapackages/:id/edit_packages' => 'metapackages#edit_packages', :method => :put
  #match '/metapackages/:id/edit_action' => 'metapackages#edit_action'

  resources :messages do
  
    member do
  get :forward
  get :reply
  end
  
  end

  resources :packages do
    collection do
  get :bundle
  get :rdepends
  get :section
  get :packagelist
  get :install_current
  get :search
  get :install_current_package
  get :install_current_source
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
  match '/users/spam_users_delete' => 'users#spam_users_delete'
  match '/users/anonymous_login' => 'users#anonymous_login'
#  match "/users/:id" => "users#show"
  match '/users/:id/destroy' => 'users#destroy'
  match '/users/:id/selfdestroy' => 'users#selfdestroy'
#  match '/users/:id/show' => 'users#show'
  resources :users do
    member do
      put :search
      get :anonymous_login
      put :enable
      put :suspend
      put :unsuspend
      delete :purge  
    end
  end  
  
  resource :account
  resources :roles

  #match '/activate/:id' => 'accounts#show', :as => :activate
  match '/forgot_password' => 'passwords#new', :as => :forgot_password
  match '/reset_password/:id' => 'passwords#edit', :as => :reset_password
  match '/change_password' => 'accounts#edit', :as => :change_password
  #match '/signup' => 'users#new', :as => :signup
  #match '/login' => 'sessions#new', :as => :login
  #match '/logout' => 'sessions#destroy', :as => :logout
  match '/logout_login' => 'sessions#logoutlogin', :as => :logout_login
  match '/admin' => 'admin#index', :as => :admin
  match '/inbox' => 'mailbox#show', :as => :inbox
  match '/:controller(/:action(/:id))'


end
