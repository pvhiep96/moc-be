class ProjectImage < ApplicationRecord
  belongs_to :project
  has_one :content_position, as: :positionable, dependent: :destroy

  validates :image_url, presence: true
  validates :image_url, uniqueness: { scope: :project_id }

  # Thuộc tính ảo để đánh dấu ảnh được chọn hiển thị
  attr_accessor :display

  # Phương thức để lấy vị trí hiển thị trong danh sách nội dung
  def display_position
    content_position&.position
  end

  # Phương thức để kiểm tra xem ảnh có được hiển thị không
  def displayed?
    content_position.present?
  end
end

# == Schema Information
#
# Table name: project_images
#
#  id         :bigint           not null, primary key
#  image_url  :string           not null
#  project_id :bigint           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_project_images_on_project_id                (project_id)
#  index_project_images_on_project_id_and_image_url  (project_id,image_url) UNIQUE
#
