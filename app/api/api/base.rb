module Api
  class Base < Grape::API
    format :json

    # Swagger documentation
    add_swagger_documentation(
      api_version: 'v1',
      hide_documentation_path: true,
      mount_path: '/swagger_doc',
      hide_format: true,
      info: {
        title: 'Project Management API',
        description: 'API để quản lý dự án với video URLs và mô tả'
      }
    )

    mount Api::V1::Base
  end
end
