class VideoUrl < ApplicationRecord
  belongs_to :project
  has_one :content_position, as: :positionable, dependent: :destroy

  before_validation :normalize_url

  validates :url, presence: true
  validate :valid_video_url

  # Phương thức để lấy vị trí hiển thị trong danh sách nội dung
  def display_position
    content_position&.position
  end

  # Phương thức để kiểm tra xem video có được hiển thị không
  def displayed?
    content_position.present?
  end

  private

  # Cho phép admin dán nguyên thẻ <iframe src="...">, link Livid hoặc link Google Drive /view, tự chuẩn hóa
  def normalize_url
    return if url.blank?

    raw = url.to_s.strip
    raw = Regexp.last_match(1).strip if raw =~ /src=["']([^"']+)["']/i

    if (gdrive_match = raw.match(%r{drive\.google\.com/file/d/([a-zA-Z0-9_-]+)}))
      self.url = "https://drive.google.com/file/d/#{gdrive_match[1]}/preview"
    elsif raw =~ %r{\Ahttps?://(www\.)?livid\.com/}i
      self.url = normalize_livid_url(raw)
    else
      self.url = raw
    end
  end

  def normalize_livid_url(raw)
    uri = URI.parse(raw)
    uri.scheme = 'https'
    return uri.to_s if uri.path.start_with?('/embed/')

    segments = uri.path.gsub(%r{\A/+|/+\z}, '').split('/')
    return raw if segments.empty?

    slug = if segments.length >= 2 && %w[v watch video videos e].include?(segments.first.downcase)
             segments.drop(1).join('/')
           else
             segments.join('/')
           end
    uri.path = "/embed/#{slug}"
    uri.to_s
  rescue URI::InvalidURIError
    raw
  end

  def valid_video_url
    return if url.blank?

    # Check for YouTube URL format (watch, youtu.be, embed, shorts, v)
    youtube_regex = %r{\A(https?://)?(www\.)?(youtube\.com/(watch\?v=|embed/|v/|shorts/|watch\?.*&v=)|youtu\.be/)([^&=%?/\s]{11})}

    # Livid (livid.com): tự động chuẩn hóa về https://livid.com/embed/...
    livid_regex = %r{\Ahttps?://(www\.)?livid\.com/embed/\S+\z}

    # Google Drive video embed: https://drive.google.com/file/d/<id>/preview
    gdrive_regex = %r{\Ahttps?://drive\.google\.com/file/d/[a-zA-Z0-9_-]+/(preview|view)}

    return if url =~ youtube_regex || url =~ livid_regex || url =~ gdrive_regex

    errors.add(:url, 'phải là URL YouTube, Livid (livid.com) hoặc Google Drive Video hợp lệ')
  end
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
