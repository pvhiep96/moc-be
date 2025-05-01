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
        project.displayed_images.first&.image_url if project.displayed_images.present?
      end

      expose :hover_image do |project, _options|
        if project.displayed_images.present? && project.displayed_images.count > 1
          project.displayed_images.second&.image_url
        end
      end

      expose :images do |project, _options|
        # Sử dụng danh sách ảnh đã được chọn hiển thị
        project.displayed_images.map(&:image_url)
      end

      expose :images_count do |project, _options|
        project.displayed_images.count
      end

      expose :video_vertical, using: Api::Entities::VideoVertical
    end
  end
end
