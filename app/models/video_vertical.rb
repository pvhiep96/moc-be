class VideoVertical < ApplicationRecord
  belongs_to :project
  has_one_attached :video_file

  validates :project_id, uniqueness: true
  validate :url_or_video_file_present

  # Validate video file type
  validate :acceptable_video, if: -> { video_file.attached? }

  def url_or_video_file_present
    return unless url.blank? && !video_file.attached?

    errors.add(:base, 'URL hoặc file video phải được cung cấp')
    errors.add(:url, 'Vui lòng nhập URL YouTube hoặc tải lên file video')
  end

  def video_url
    if video_file.attached? && !video_file.blob.new_record?
      begin
        host = if Rails.env.production?
                 'https://mocproductions.com/'
               else
                 nil # Will use relative URL in development
               end

        if host
          Rails.application.routes.url_helpers.rails_blob_url(video_file, host: host)
        else
          Rails.application.routes.url_helpers.rails_blob_url(video_file, only_path: true)
        end
      rescue StandardError => e
        Rails.logger.error("Error generating video URL: #{e.message}")
        nil
      end
    else
      url
    end
  end

  def acceptable_video
    return unless video_file.attached?

    # Check file size
    unless video_file.blob.byte_size <= 500.megabytes
      errors.add(:video_file, 'quá lớn (tối đa là 500MB)')
      video_file.purge
      return
    end

    # Check content type
    acceptable_types = ['video/mp4', 'video/quicktime', 'video/x-msvideo', 'video/x-flv', 'video/webm']
    return if acceptable_types.include?(video_file.content_type)

    errors.add(:video_file, 'phải là định dạng video hợp lệ (MP4, MOV, AVI, FLV, WEBM)')
    video_file.purge
  end
end

# == Schema Information
#
# Table name: video_verticals
#
#  id         :bigint           not null, primary key
#  project_id :bigint           not null
#  url        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_video_verticals_on_project_id  (project_id) UNIQUE
#
