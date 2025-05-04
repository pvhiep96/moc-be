module Api
  module Entities
    class VideoUrl < Grape::Entity
      expose :id
      expose :url

      expose :position do |video, _options|
        video.display_position
      end

      expose :displayed do |video, _options|
        video.displayed?
      end
    end
  end
end
