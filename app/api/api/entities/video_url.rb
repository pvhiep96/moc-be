module Api
  module Entities
    class VideoUrl < Grape::Entity
      expose :id
      expose :url

      expose :position do |video, _options|
        video.display_position
      end
    end
  end
end
