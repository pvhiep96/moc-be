class VideoUrl < ApplicationRecord
  belongs_to :project
  has_one :content_position, as: :positionable, dependent: :destroy

  validates :url, presence: true
  validate :valid_video_url

  # Phương thức để lấy vị trí hiển thị trong danh sách nội dung
  def display_position
    content_position&.position
  end

  # Phương thức để kiểm tra xem video có được hiển thị không
  def displayed?
    content_position.present?
  end

  private

  def valid_video_url
    return if url.blank?

    # Check for YouTube URL format
    youtube_regex = %r{^(https?://)?(www\.)?(youtube\.com/watch\?v=|youtu\.be/|youtube\.com/embed/|youtube\.com/v/|youtube\.com/watch\?.*&v=)([^&=%?]{11})}

    return if url =~ youtube_regex

    errors.add(:url, 'phải là URL YouTube hợp lệ')
  end
end

# == Schema Information
#
# Table name: video_urls
#
#  id         :bigint           not null, primary key
#  project_id :bigint           not null
#  url        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_video_urls_on_project_id  (project_id)
#
