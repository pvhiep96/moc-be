class Project < ApplicationRecord
  has_many :video_urls, dependent: :destroy
  has_many :descriptions, dependent: :destroy
  has_many :project_images, dependent: :destroy
  has_one :video_vertical, dependent: :destroy
  has_many :content_positions, dependent: :destroy

  # Mặc định tự động đưa nội dung mới thêm (ảnh Drive mới, video mới, mô tả mới) lên website
  attribute :auto_display_new_content, :boolean, default: true

  before_validation :normalize_drive_id

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :drive_id,
            format: { with: /\A[a-zA-Z0-9_-]+\z/, message: 'chỉ gồm chữ cái, chữ số, dấu gạch dưới (_) hoặc gạch ngang (-)' },
            allow_blank: true

  accepts_nested_attributes_for :video_urls, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :descriptions, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :video_vertical, allow_destroy: true, reject_if: :all_blank

  after_save :fetch_and_save_images
  after_save :auto_append_new_content_positions

  # Kết quả lần đồng bộ Google Drive gần nhất (trong cùng request)
  attr_reader :drive_sync_count, :drive_sync_error, :drive_added_count, :drive_removed_count, :drive_video_count

  # Cho phép dán nguyên đường link Google Drive Folder hoặc Drive ID đều tự tách đúng ID
  def self.extract_drive_id(raw)
    value = raw.to_s.strip
    return '' if value.blank?

    if (match = value.match(%r{/folders/([a-zA-Z0-9_-]+)}))
      match[1]
    elsif (match = value.match(/[?&]id=([a-zA-Z0-9_-]+)/))
      match[1]
    else
      value
    end
  end

  def drive_sync_failed?
    drive_id.present? && (drive_sync_error.present? || (drive_sync_count.to_i.zero? && drive_video_count.to_i.zero?))
  end

  def images
    project_images.pluck(:image_url)
  end

  # Đồng bộ lại danh sách ảnh + video + file mô tả từ Google Drive
  def reload_images(prune_removed: false)
    fetch_and_save_images(prune_removed: prune_removed)
    auto_append_new_content_positions if auto_display_new_content
    images
  end

  # Đưa toàn bộ nội dung chưa hiển thị vào danh sách hiển thị
  def display_all_content!(only_type: nil)
    ActiveRecord::Base.transaction do
      next_pos = (content_positions.maximum(:position) || -1) + 1
      existing_keys = content_positions.pluck(:positionable_type, :positionable_id).to_set

      collections = [
        ['VideoUrl', video_urls.order(:id)],
        ['Description', descriptions.order(:id)],
        ['ProjectImage', project_images.order(:id)]
      ]

      collections.each do |type, scope|
        next if only_type.present? && only_type != type

        scope.each do |record|
          next if existing_keys.include?([type, record.id])

          content_positions.create!(
            positionable_type: type,
            positionable_id: record.id,
            position: next_pos
          )
          existing_keys.add([type, record.id])
          next_pos += 1
        end
      end
    end
  end

  # Lấy danh sách ảnh đã được chọn hiển thị theo thứ tự
  def displayed_images
    displayed_records('ProjectImage', project_images)
  end

  # Lấy danh sách video đã được chọn hiển thị theo thứ tự
  def displayed_videos
    displayed_records('VideoUrl', video_urls)
  end

  # Lấy danh sách mô tả đã được chọn hiển thị theo thứ tự
  def displayed_descriptions
    displayed_records('Description', descriptions)
  end

  # Content positions đã sắp xếp theo position
  def sorted_content_positions
    content_positions.sort_by(&:position)
  end

  # Lấy danh sách tất cả nội dung đã được sắp xếp theo thứ tự
  def ordered_content
    sorted_content_positions.map(&:positionable)
  end

  private

  def normalize_drive_id
    self.drive_id = self.class.extract_drive_id(drive_id) if drive_id.present?
  end

  def displayed_records(type, records)
    ids = sorted_content_positions.select { |cp| cp.positionable_type == type }.map(&:positionable_id)
    by_id = records.index_by(&:id)
    ids.filter_map { |id| by_id[id] }
  end

  def fetch_and_save_images(prune_removed: false)
    @newly_created_image_ids ||= []
    @newly_created_video_ids ||= []
    @newly_created_desc_ids ||= []
    @drive_added_count = 0
    @drive_removed_count = 0
    @drive_video_count = 0
    return [] if drive_id.blank?

    Rails.logger.info("Fetching folder contents for project: #{name} (ID: #{id}, Drive ID: #{drive_id})")

    begin
      drive_service = ::GoogleDriveService.new
      contents = drive_service.get_folder_contents(drive_id)
      image_urls = contents[:images] || []
      video_entries = contents[:videos] || []
      docx_htmls = contents[:descriptions] || []

      Rails.logger.info("Found #{image_urls.length} images, #{video_entries.length} videos, #{docx_htmls.length} docs for project #{name}")

      # 1. Lưu ảnh
      formatted_urls = image_urls.map { |url| "#{url}=s0" }
      existing_by_url = project_images.index_by(&:image_url)

      formatted_urls.each do |formatted_url|
        next if existing_by_url.key?(formatted_url)

        created = project_images.create(image_url: formatted_url)
        if created.persisted?
          @newly_created_image_ids << created.id
          @drive_added_count += 1
        end
      end

      if prune_removed && formatted_urls.any?
        stale_images = project_images.where.not(image_url: formatted_urls)
        @drive_removed_count = stale_images.count
        if @drive_removed_count.positive?
          stale_ids = stale_images.pluck(:id)
          content_positions.where(positionable_type: 'ProjectImage', positionable_id: stale_ids).destroy_all
          stale_images.destroy_all
        end
      end

      # 2. Lưu video trong thư mục VIDEO của Google Drive (nếu chưa có)
      existing_video_urls = video_urls.pluck(:url).to_set
      video_entries.each do |v_entry|
        next if existing_video_urls.include?(v_entry[:url])

        created_video = video_urls.create(url: v_entry[:url])
        if created_video.persisted?
          @newly_created_video_ids << created_video.id
          existing_video_urls.add(v_entry[:url])
        end
      end

      # 3. Lưu nội dung mô tả/credit từ file .docx trong thư mục Drive (nếu dự án chưa có mô tả)
      if descriptions.empty? && docx_htmls.any?
        docx_htmls.each do |html|
          created_desc = descriptions.create(content: html)
          @newly_created_desc_ids << created_desc.id if created_desc.persisted?
        end
      end

      @drive_sync_count = image_urls.length
      @drive_video_count = video_entries.length
      @drive_sync_error = nil
      image_urls
    rescue StandardError => e
      Rails.logger.error("Error fetching contents from Google Drive: #{e.message}")
      @drive_sync_count = 0
      @drive_sync_error = e.message
      []
    end
  end

  # Tự động gắn ContentPosition cho những bản ghi mới vừa được tạo trong lần lưu này
  def auto_append_new_content_positions
    return unless auto_display_new_content

    existing_keys = content_positions.pluck(:positionable_type, :positionable_id).to_set
    next_pos = (content_positions.maximum(:position) || -1) + 1

    # Ảnh Google Drive mới (đưa ảnh lên đầu trước để có Ảnh Bìa & Ảnh Hover ngay lập tức)
    Array(@newly_created_image_ids).each do |img_id|
      next if existing_keys.include?(['ProjectImage', img_id])

      content_positions.create(
        positionable_type: 'ProjectImage',
        positionable_id: img_id,
        position: next_pos
      )
      existing_keys.add(['ProjectImage', img_id])
      next_pos += 1
    end

    # Video mới (từ form hoặc từ thư mục VIDEO trên Drive)
    new_video_ids = (video_urls.select(&:saved_change_to_id?).map(&:id) + Array(@newly_created_video_ids)).uniq
    new_video_ids.each do |vid_id|
      next if existing_keys.include?(['VideoUrl', vid_id])

      content_positions.create(
        positionable_type: 'VideoUrl',
        positionable_id: vid_id,
        position: next_pos
      )
      existing_keys.add(['VideoUrl', vid_id])
      next_pos += 1
    end

    # Mô tả mới (từ form hoặc từ file .docx trên Drive)
    new_desc_ids = (descriptions.select(&:saved_change_to_id?).map(&:id) + Array(@newly_created_desc_ids)).uniq
    new_desc_ids.each do |desc_id|
      next if existing_keys.include?(['Description', desc_id])

      content_positions.create(
        positionable_type: 'Description',
        positionable_id: desc_id,
        position: next_pos
      )
      existing_keys.add(['Description', desc_id])
      next_pos += 1
    end

    @newly_created_image_ids = []
    @newly_created_video_ids = []
    @newly_created_desc_ids = []
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
