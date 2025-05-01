class VideoUrl < ApplicationRecord
  belongs_to :project
  has_one :content_position, as: :positionable, dependent: :destroy

  validates :url, presence: true

  # Phương thức để lấy vị trí hiển thị trong danh sách nội dung
  def display_position
    content_position&.position
  end

  # Phương thức để kiểm tra xem video có được hiển thị không
  def displayed?
    content_position.present?
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
