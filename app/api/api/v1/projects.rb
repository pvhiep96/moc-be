module Api
  module V1
    class Projects < Grape::API
      resource :projects do
        desc 'Lấy danh sách tất cả các dự án'
        get do
          projects = Project.includes(:video_urls, :video_vertical)
          present projects, with: Api::Entities::Project
        end

        desc 'Lấy thông tin chi tiết của một dự án'
        params do
          requires :id, type: Integer, desc: 'ID của dự án'
        end
        get ':id' do
          project = Project.includes(
            :video_urls,
            :descriptions,
            :project_images,
            :video_vertical,
            content_positions: :positionable
          ).find(params[:id])

          present project, with: Api::Entities::Project
        end

        desc 'Lấy thông tin chi tiết của một dự án với tất cả các ảnh'
        params do
          requires :id, type: Integer, desc: 'ID của dự án'
        end
        get ':id/full' do
          project = Project.includes(
            :video_urls,
            :descriptions,
            :project_images,
            :video_vertical,
            content_positions: :positionable
          ).find(params[:id])

          present project, with: Api::Entities::ProjectWithAllImages
        end
      end
    end
  end
end
