require 'jwt'

module Api
  module V1
    module Admin
      class Auth < Grape::API
        include ::Api::V1::Defaults
        namespace :admin do
        resource :auth do
          desc 'Login as admin'
          params do
            requires :user_name, type: String, desc: 'Admin user_name'
            requires :password, type: String, desc: 'Admin password'
          end
          get :login do
            admin = Admin.find_by(user_name: params[:user_name])
            if admin&.authenticate(params[:password])
              payload = {admin_id: admin.id, exp: 24.hours.from_now.to_i}
              token = JWT.encode(payload, Rails.application.secret_key_base)
              {token: token, message: 'Login successful'}
            else
              error!({error: 'Invalid user_name or password'}, 401)
            end
          end
          end
        end
      end
    end
  end
end
