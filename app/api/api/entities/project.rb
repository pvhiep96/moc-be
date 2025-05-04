module Api
  module Entities
    class Project < Grape::Entity
      expose :id
      expose :name
      expose :drive_id
      expose :show_video
      expose :video_vertical, using: Api::Entities::VideoVertical

      expose :cover_image do |project, _options|
        project.displayed_images.first&.image_url if project.displayed_images.present?
      end

      expose :hover_image do |project, _options|
        if project.displayed_images.present? && project.displayed_images.count > 1
          project.displayed_images.second&.image_url
        end
      end

      # Thêm danh sách nội dung đã được sắp xếp theo thứ tự hiển thị
      expose :ordered_content do |project, _options|
        ordered_items = project.content_positions.includes(:positionable).order(:position)

        ordered_items.map do |position|
          item = position.positionable
          positionable_type = position.positionable_type

          case positionable_type
          when 'ProjectImage'
            {
              id: item.id,
              type: 'images',
              position: position.position,
              image_url: item.image_url
            }
          when 'Description'
            {
              id: item.id,
              type: 'description',
              position: position.position,
              content: item.content
            }
          when 'VideoUrl'
            {
              id: item.id,
              type: 'video',
              position: position.position,
              url: item.url
            }
          else
            {
              id: item.id,
              type: 'unknown',
              position: position.position
            }
          end
        end
      end

      # Giữ lại các trường cũ để tương thích ngược
      expose :images do |project, _options|
        project.displayed_images.map(&:image_url)
      end

      expose :images_count do |project, _options|
        project.displayed_images.count
      end

      expose :video_urls, using: Api::Entities::VideoUrl
      expose :descriptions, using: Api::Entities::Description
    end
  end
end
