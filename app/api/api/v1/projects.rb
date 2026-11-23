module Api
  module V1
    class Projects < Grape::API
      PROJECT_PRELOADS = [
        :video_urls,
        :descriptions,
        :project_images,
        { video_vertical: { video_file_attachment: :blob } },
        { content_positions: :positionable }
      ].freeze

      resource :projects do
        desc 'Lấy cấu hình nội dung Trang Chủ (Home Settings)'
        get 'site_settings' do
          header 'Cache-Control', 'no-store'
          SiteSetting.all
        end

        desc 'Lấy danh sách tất cả các dự án'
        get do
          # Preload toàn bộ association mà entity dùng → số query cố định, không phụ thuộc số project
          projects = Project.includes(*PROJECT_PRELOADS).order(:id)
          header 'Cache-Control', 'no-store'
          present projects, with: Api::Entities::Project
        end

        desc 'Lấy thông tin chi tiết của một dự án'
        params do
          requires :id, type: Integer, desc: 'ID của dự án'
        end
        get ':id' do
          project = Project.includes(*PROJECT_PRELOADS).find(params[:id])
          header 'Cache-Control', 'no-store'
          present project, with: Api::Entities::Project
        end

        desc 'Lấy thông tin chi tiết của một dự án với tất cả các ảnh'
        params do
          requires :id, type: Integer, desc: 'ID của dự án'
        end
        get ':id/full' do
          project = Project.includes(*PROJECT_PRELOADS).find(params[:id])
          header 'Cache-Control', 'no-store'
          present project, with: Api::Entities::ProjectWithAllImages
        end
      end
    end
  end
end
