module Api
  module Entities
    class ContentPosition < Grape::Entity
      expose :id
      expose :positionable_type
      expose :positionable_id
      expose :position
    end
  end
end
