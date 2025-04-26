Rails.application.routes.draw do
  # Sessions routes
  get 'login', to: 'sessions#new', as: 'login'
  post 'sessions', to: 'sessions#create', as: 'sessions'
  delete 'logout', to: 'sessions#destroy', as: 'logout'

  resources :projects do
    member do
      post :reload_images
    end
  end

  # API routes
  mount Api::Base, at: '/api'
  mount GrapeSwaggerRails::Engine => '/swagger'

  root to: 'projects#index'
end
