# frozen_string_literal: true
require 'grape-swagger'
module Api
  module V1
    class Base < Grape::API
      format :json
      mount Api::V1::Admin::Auth

      resource :test do
        desc 'Test protected route'
        get :protected do
          { message: 'You are authenticated!', current_user: env['current_admin'].user_name }
        end
      end

      add_swagger_documentation(
        api_version:             'v1',
        hide_documentation_path: true,
        mount_path:              '/api/v1/swagger_doc',
        hide_format:             true,
        info:                    {
          title: 'Apis endpoint'
        }
      )
    end
  end
end
