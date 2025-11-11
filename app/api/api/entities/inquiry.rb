# app/api/api/v1/entities/inquiry.rb
module Api
  module Entities
    class Inquiry < Grape::Entity
      expose :id
      expose :full_name
      expose :email
      expose :location
      expose :event_type
      expose :role
      expose :event_date
      expose :event_location
      expose :budget
      expose :instagram
      expose :source
      expose :message
      expose :created_at
      expose :updated_at
    end
  end
end

# Helper for ISO date formatting
Grape::Entity.format_with :iso8601 do |date|
  date&.iso8601
end
