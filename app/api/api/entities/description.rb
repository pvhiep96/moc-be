module Api
  module Entities
    class Description < Grape::Entity
      expose :id
      expose :content

      expose :position do |description, _options|
        description.display_position
      end

      expose :displayed do |description, _options|
        description.displayed?
      end
    end
  end
end
