module Api
  module V1
    class Base < Grape::API
      version 'v1', using: :path

      mount Api::V1::Projects
      mount Api::V1::Inquiries
    end
  end
end
