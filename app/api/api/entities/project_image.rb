module Api
  module Entities
    class ProjectImage < Grape::Entity
      expose :id
      expose :image_url

      expose :position do |image, _options|
        image.display_position
      end
    end
  end
end
