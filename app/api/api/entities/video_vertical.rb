module Api
  module Entities
    class VideoVertical < Grape::Entity
      expose :url

      expose :video_url do |video_vertical, _options|
        if video_vertical.video_file.attached? && !video_vertical.video_file.blob.new_record?
          begin
            host = if Rails.env.production?
                     'https://mocproductions.com/'
                   else
                     ActionController::Base.asset_host ||
                       "#{_options[:env]['rack.url_scheme']}://#{_options[:env]['HTTP_HOST']}"
                   end

            Rails.application.routes.url_helpers.rails_blob_url(
              video_vertical.video_file,
              host: host
            )
          rescue StandardError => e
            Rails.logger.error("Error generating video URL in API: #{e.message}")
            video_vertical.url
          end
        else
          video_vertical.url
        end
      end

      expose :has_uploaded_video do |video_vertical, _options|
        video_vertical.video_file.attached? && !video_vertical.video_file.blob.new_record?
      end

      expose :video_type do |video_vertical, _options|
        if video_vertical.video_file.attached?
          'file'
        elsif video_vertical.url.present?
          'youtube'
        else
          nil
        end
      end

      expose :video_metadata, if: lambda { |video_vertical, _|
        video_vertical.video_file.attached? && !video_vertical.video_file.blob.new_record?
      } do |video_vertical, _options|
        {
          filename: video_vertical.video_file.filename.to_s,
          content_type: video_vertical.video_file.content_type,
          byte_size: video_vertical.video_file.byte_size,
          created_at: video_vertical.video_file.created_at
        }
      end
    end
  end
end
