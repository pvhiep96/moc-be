Rails.application.routes.draw do
  # Sessions routes
  get 'login', to: 'sessions#new', as: 'login'
  post 'sessions', to: 'sessions#create', as: 'sessions'
  delete 'logout', to: 'sessions#destroy', as: 'logout'

  resources :projects do
    collection do
      get :home_manager
      post :update_home_settings
      post :reset_home_settings
      get :studio_manager
      get :detail_manager
    end

    member do
      post :reload_images
      post :toggle_video
      post :display_all_content
      get :manage_content
      post :update_content
      get :content_item
      post :update_content_positions
      post :quick_set_studio_media
    end
  end

  resources :inquiries, only: %i[index show destroy]

  # Sửa giao diện website (xem trực tiếp + click vào vùng cần sửa)
  get 'site_editor(/:page)', to: 'site_editor#show', as: :site_editor
  patch 'site_editor', to: 'site_editor#update', as: :update_site_editor
  post 'site_editor/upload', to: 'site_editor#upload', as: :upload_site_editor

  # API routes
  mount Api::Base, at: '/api'
  mount GrapeSwaggerRails::Engine => '/swagger'

  root 'site_editor#show'
end
