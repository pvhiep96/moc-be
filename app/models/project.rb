class Project < ApplicationRecord
  has_many :video_urls, dependent: :destroy
  has_many :descriptions, dependent: :destroy
  has_many :project_images, dependent: :destroy
  has_one :video_vertical, dependent: :destroy # Changed from has_many to has_one

  validates :name, presence: true
  # validates :drive_id, presence: true

  accepts_nested_attributes_for :video_urls, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :descriptions, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :video_vertical, allow_destroy: true, reject_if: :all_blank # Changed from video_verticals to video_vertical

  after_save :fetch_and_save_images

  def images
    project_images.pluck(:image_url)
  end

  # Force reload images from Google Drive
  def reload_images
    # Clear existing images
    project_images.destroy_all

    # Fetch new images and save them
    fetch_and_save_images

    # Return the fresh list of images
    images
  end

  private

  def fetch_and_save_images
    return [] if drive_id.blank?

    Rails.logger.info("Fetching images for project: #{name} (ID: #{id}, Drive ID: #{drive_id})")

    begin
      drive_service = ::GoogleDriveService.new
      image_urls = drive_service.get_image_urls(drive_id)
      Rails.logger.info("Found #{image_urls.length} images for project #{name}")

      # Save each image URL to the project_images table
      image_urls.each do |url|
        project_images.create!(image_url: "#{url}=s0")
      end

      image_urls
    rescue StandardError => e
      Rails.logger.error("Error fetching images from Google Drive: #{e.message}")
      []
    end
  end
end

# == Schema Information
#
# Table name: projects
#
#  id         :bigint           not null, primary key
#  name       :string
#  drive_id   :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  show_video :boolean
#
