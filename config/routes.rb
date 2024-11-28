# frozen_string_literal: true

Rails.application.routes.draw do
  mount ActionCable.server => '/cable'

  devise_for :users
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # Only using this to start, will change later
  root 'welcome#home'

  get 'main_menu', to: 'main_menu#index', as: 'main_menu'

  resources :servers do
    resources :messages, only: [:create]
    member do
      post :update_status
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
