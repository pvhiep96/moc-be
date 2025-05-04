class Description < ApplicationRecord
  belongs_to :project
  has_one :content_position, as: :positionable, dependent: :destroy

  # validates :position_display, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :content, presence: true

  # Phương thức để lấy vị trí hiển thị trong danh sách nội dung
  def display_position
    content_position&.position
  end

  # Phương thức để kiểm tra xem mô tả có được hiển thị không
  def displayed?
    content_position.present?
  end
end

# == Schema Information
#
# Table name: descriptions
#
#  id               :bigint           not null, primary key
#  project_id       :bigint           not null
#  position_display :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  content          :text
#
# Indexes
#
#  index_descriptions_on_project_id  (project_id)
#
