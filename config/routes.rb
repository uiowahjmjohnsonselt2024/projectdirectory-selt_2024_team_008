# frozen_string_literal: true

# Helper method to safely check if the route exists
# def safe_recognize_path(req)
#   Rails.application.routes.recognize_path(req.path, method: req.method)
# rescue ActionController::RoutingError, StandardError
#   false
# end

Rails.application.routes.draw do
  get 'character_creation/index'
  # Mount ActionCable server
  mount ActionCable.server => '/cable'

  # Devise routes for user authentication and omni auth
  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks'
  }

  # You can have the root of your site routed with "root"
  # Only using this to start, will change later
  root 'welcome#home'

  # match '*unmatched', to: 'errors#handle_invalid_route', via: :all, constraints: ->(req) {
  #   !ShardsOfTheGrid::Application.valid_route?(req.path, req.method) &&
  #     req.path.exclude?('rails/active_storage')
  # }

  # Define main_menu with role constraints
  get 'main_menu', to: 'main_menu#index', as: 'main_menu'

  # Server routes
  resources :servers, only: [:index, :create, :show] do
    resources :messages, only: [:index, :create]
    resources :memberships, only: [:create, :destroy]
    member do
      post :update_status
      post :ensure_membership, defaults: { format: :json }
    end
  end

  # Game routes
  resources :games, only: [:create, :show, :index] do
    resources :memberships, only: [:create, :destroy], defaults: { format: :json }
    member do
      get :game_state, defaults: { format: :json }
      post :ensure_membership, defaults: { format: :json }
    end
  end

  resources :shard_accounts, only: [] do
    collection do
      post :add_funds    # To handle adding funds
      post :buy_item
      get :buy_shards
      post :convert_currency
    end
  end

  resources :shop, only: [:index, :show]

  get '/mystery_box', to: 'mystery_boxes#open'
  post 'mystery_boxes/open_box', to: 'mystery_boxes#open_box', as: 'open_mystery_box'

  resources :mystery_boxes, only: [] do
    collection do
      get 'open', to: 'mystery_boxes#open'
    end
  end


  get 'inventory', to: 'inventory#show', as: 'inventory'

  get 'instructions', to: 'instructions#show', as: 'instructions'



  resources :npc_task, only: [:create] do
    member do
      post :answer_riddle
    end
  end

  get 'character_creation', to: 'character_creation#index'
  resources :character_creation, only: [:index] do
    patch :equip_item, on: :collection
  end
  resources :character_creation, only: [:index] do
    patch :equip_item, on: :collection
    patch :unequip_item, on: :collection
  end

  resources :character_creation, only: [:index] do
    patch :generate_avatar, on: :collection
  end

  post '/npc_task/chat', to: 'npc_task#chat'

  get 'npc_task', to: 'npc_task#show', as: 'npc_task'

  resources :math_task, only: [:create] do
    member do
      post :answer_math
    end
  end

  post '/math_task/chat', to: 'math_task#chat'

  get 'math_task', to: 'math_task#show', as: 'math_task'


  # Catch-all route for unknown paths
  # match '*unmatched', to: 'errors#redirect_to_main_menu', via: :all, constraints: ->(req) {
  #   req.format.html? &&
  #     req.path.exclude?('rails/active_storage') &&
  #     req.path.exclude?('/main_menu') && # Exclude paths that could match valid routes
  #     req.path.exclude?('/game/')
  # }

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
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

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end