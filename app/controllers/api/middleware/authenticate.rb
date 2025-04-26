module Api
  module Middleware
    class Authenticate
      def initialize(app)
        @app = app
      end

      def call(env)
        request = Rack::Request.new(env)
        return @app.call(env) if request.path.start_with?('/api/v1/auth/login')

        token = request.get_header('HTTP_AUTHORIZATION')&.split(' ')&.last
        Rails.logger.info "Received token: #{token}"

        begin
          secret_key = Rails.application.secret_key_base || ENV['SECRET_KEY_BASE']
          payload = JWT.decode(token, secret_key).first
          Rails.logger.info "Decoded payload: #{payload}"
          env['current_admin'] = Admin.find(payload['admin_id'])
        rescue JWT::DecodeError, ActiveRecord::RecordNotFound => e
          Rails.logger.error "JWT decode error: #{e.message}"
          return [401, {'Content-Type' => 'application/json'}, [{error: 'Unauthorized'}.to_json]]
        end

        @app.call(env)
      end
    end
  end
end
