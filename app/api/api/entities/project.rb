module Api
  module Entities
    class Project < Grape::Entity
      expose :id
      expose :name
      expose :drive_id
      expose :video_urls, using: Api::Entities::VideoUrl
      expose :descriptions, using: Api::Entities::Description
      expose :show_video

      expose :cover_image do |project, _options|
        project.images.first if project.images.present?
      end

      expose :hover_image do |project, _options|
        project.images.second if project.images.present? && project.images.count > 1
      end

      expose :images do |project, _options|
        # Limit to 6 images as requested
        project.images || []
      end

      expose :images_count do |project, _options|
        project.images.count
      end

      expose :video_vertical, using: Api::Entities::VideoVertical
    end
  end
end
