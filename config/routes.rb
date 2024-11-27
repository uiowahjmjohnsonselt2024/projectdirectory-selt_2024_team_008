# frozen_string_literal: true

Rails.application.routes.draw do
  # Mount ActionCable server
  mount ActionCable.server => '/cable'

  # Devise routes for user authentication
  devise_for :users

  # Root route
  root 'main_menu#index'

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
  resources :games, only: [:create, :show, :index]


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
