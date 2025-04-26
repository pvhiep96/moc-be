class VideoUrl < ApplicationRecord
  belongs_to :project

  validates :url, presence: true
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
