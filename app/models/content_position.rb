class ContentPosition < ApplicationRecord
  belongs_to :project
  belongs_to :positionable, polymorphic: true

  validates :position, presence: true, uniqueness: { scope: :project_id }
  validates :positionable_id, uniqueness: { scope: %i[project_id positionable_type] }

  # Đảm bảo mỗi positionable chỉ có một content_position
  validates :positionable_id, uniqueness: { scope: :positionable_type, message: 'đã có vị trí hiển thị' }
end

# == Schema Information
#
# Table name: content_positions
#
#  id               :bigint           not null, primary key
#  project_id       :bigint           not null
#  positionable_type :string           not null
#  positionable_id   :bigint           not null
#  position         :integer          not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_content_positions_on_positionable  (positionable_type,positionable_id) UNIQUE
#  index_content_positions_on_project_id    (project_id)
#  index_content_positions_on_project_id_and_position  (project_id,position) UNIQUE
#
