Rails.application.routes.draw do
  # Sessions routes
  get 'login', to: 'sessions#new', as: 'login'
  post 'sessions', to: 'sessions#create', as: 'sessions'
  delete 'logout', to: 'sessions#destroy', as: 'logout'

  resources :projects do
    member do
      post :reload_images
      get :manage_content
      post :update_content
      get :content_item
      post :update_content_positions
    end
  end

  # API routes
  mount Api::Base, at: '/api'
  mount GrapeSwaggerRails::Engine => '/swagger'

  root 'projects#index'
end
