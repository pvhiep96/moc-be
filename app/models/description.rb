class Description < ApplicationRecord
  belongs_to :project

  validates :position_display, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :content, presence: true
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
