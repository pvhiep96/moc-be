class VideoVertical < ApplicationRecord
  belongs_to :project

  validates :url, presence: true
  validates :project_id, uniqueness: true
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
