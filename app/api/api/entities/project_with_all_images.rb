module Api
  module Entities
    class ProjectWithAllImages < Grape::Entity
      expose :id
      expose :name
      expose :drive_id
      expose :video_urls, using: Api::Entities::VideoUrl
      expose :descriptions, using: Api::Entities::Description
      expose :show_video

      # Vẫn giữ lại ảnh đã được chọn hiển thị
      expose :cover_image do |project, _options|
        project.displayed_images.first&.image_url if project.displayed_images.present?
      end

      expose :hover_image do |project, _options|
        if project.displayed_images.present? && project.displayed_images.count > 1
          project.displayed_images.second&.image_url
        end
      end

      # Danh sách ảnh đã được chọn hiển thị
      expose :images do |project, _options|
        project.displayed_images.map(&:image_url)
      end

      expose :images_count do |project, _options|
        project.displayed_images.count
      end

      # Thêm tất cả các ảnh của dự án
      expose :all_images do |project, _options|
        project.project_images.map(&:image_url)
      end

      expose :all_images_count do |project, _options|
        project.project_images.count
      end

      expose :video_vertical, using: Api::Entities::VideoVertical
    end
  end
end
