class Description < ApplicationRecord
  belongs_to :project
  has_one :content_position, as: :positionable, dependent: :destroy

  validates :content, presence: { message: 'cannot be blank' }
  validate :content_not_just_html

  # Phương thức để lấy vị trí hiển thị trong danh sách nội dung
  def display_position
    content_position&.position
  end

  # Phương thức để kiểm tra xem mô tả có được hiển thị không
  def displayed?
    content_position.present?
  end

  private

  def content_not_just_html
    return if content.blank?

    # Strip HTML tags and check if there's any content left
    stripped_content = ActionController::Base.helpers.strip_tags(content).strip
    return unless stripped_content.blank?

    errors.add(:content, 'cannot contain only HTML tags without any text')
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
