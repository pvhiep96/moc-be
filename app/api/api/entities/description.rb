module Api
  module Entities
    class Description < Grape::Entity
      expose :id
      expose :content
      expose :position_display
    end
  end
end
