module Api
  module V1
    class SiteContent < Grape::API
      resource :site_content do
        desc 'Toàn bộ nội dung chữ / link / ảnh của website (đã gộp giá trị mặc định)'
        get do
          header 'Cache-Control', 'no-store'
          ::SiteContent.content_values
        end
      end
    end
  end
end
