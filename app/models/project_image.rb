class ProjectImage < ApplicationRecord
  belongs_to :project
  
  validates :image_url, presence: true
  validates :image_url, uniqueness: { scope: :project_id }
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
