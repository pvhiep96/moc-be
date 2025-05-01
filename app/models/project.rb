class Project < ApplicationRecord
  has_many :video_urls, dependent: :destroy
  has_many :descriptions, dependent: :destroy
  has_many :project_images, dependent: :destroy
  has_one :video_vertical, dependent: :destroy
  has_many :content_positions, dependent: :destroy

  validates :name, presence: true
  # validates :drive_id, presence: true

  accepts_nested_attributes_for :video_urls, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :descriptions, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :video_vertical, allow_destroy: true, reject_if: :all_blank

  after_save :fetch_and_save_images

  def images
    project_images.pluck(:image_url)
  end

  # Force reload images from Google Drive
  def reload_images
    # Clear existing images
    # project_images.destroy_all

    # Fetch new images and save them
    fetch_and_save_images

    # Return the fresh list of images
    images
  end

  # Lấy danh sách ảnh đã được chọn hiển thị theo thứ tự
  def displayed_images
    image_positions = content_positions.where(positionable_type: 'ProjectImage').order(:position)
    image_ids = image_positions.pluck(:positionable_id)
    project_images.where(id: image_ids).sort_by { |img| image_ids.index(img.id) }
  end

  # Lấy danh sách video đã được chọn hiển thị theo thứ tự
  def displayed_videos
    video_positions = content_positions.where(positionable_type: 'VideoUrl').order(:position)
    video_ids = video_positions.pluck(:positionable_id)
    video_urls.where(id: video_ids).sort_by { |vid| video_ids.index(vid.id) }
  end

  # Lấy danh sách mô tả đã được chọn hiển thị theo thứ tự
  def displayed_descriptions
    desc_positions = content_positions.where(positionable_type: 'Description').order(:position)
    desc_ids = desc_positions.pluck(:positionable_id)
    descriptions.where(id: desc_ids).sort_by { |desc| desc_ids.index(desc.id) }
  end

  # Lấy danh sách tất cả nội dung đã được sắp xếp theo thứ tự
  def ordered_content
    content_positions.includes(:positionable).order(:position).map(&:positionable)
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
        formatted_url = "#{url}=s0"
        # Kiểm tra xem ảnh đã tồn tại chưa trước khi tạo mới
        project_images.find_or_create_by(image_url: formatted_url)
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
