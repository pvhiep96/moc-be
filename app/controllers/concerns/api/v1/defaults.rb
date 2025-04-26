# frozen_string_literal: true

require 'grape_logging'

module Api
  module V1
    module Defaults
      extend ActiveSupport::Concern

      included do
        # include Grape::Kaminari

        prefix :api
        version 'v1', using: :path
        default_format :json
        format :json

        use GrapeLogging::Middleware::RequestLogger,
            instrumentation_key: 'grape_key',
            include:             [GrapeLogging::Loggers::FilterParameters.new,
                                  GrapeLogging::Loggers::RequestHeaders.new,
                                  GrapeLogging::Loggers::RequestHeaders.new]

        helpers do
          def permitted_params
            @permitted_params ||= declared(params, include_missing: false)
          end

          def logger
            Rails.logger
          end
        end

        rescue_from ActiveRecord::RecordNotFound do |exception|
          error_response(message: exception.message, status: 404)
        end

        rescue_from ActiveRecord::RecordInvalid do |exception|
          error_response(message: exception.record.errors, status: 422)
        end
      end
    end
  end
end
