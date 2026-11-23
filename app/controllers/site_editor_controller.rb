# "Sửa giao diện website": xem trang thật (iframe moc-fe ở chế độ sửa) + ô nhập theo từng vùng.
class SiteEditorController < ApplicationController
  before_action :require_admin

  UPLOAD_RULES = {
    'image' => { types: %w[image/jpeg image/png image/webp image/gif image/avif], max: 20.megabytes,
                 label: 'ảnh JPG, PNG, WebP, GIF, AVIF', max_label: '20MB' },
    'video' => { types: %w[video/mp4 video/webm video/quicktime], max: 500.megabytes,
                 label: 'video MP4, WebM, MOV', max_label: '500MB' }
  }.freeze

  def show
    @pages = SiteContent.content_pages
    @values = SiteContent.content_values
    @defaults = SiteContent.content_defaults
    @active_page = @pages.find { |p| p['id'] == params[:page] } || @pages.first
    @projects = Project.order(id: :desc).select(:id, :name)
    @frontend_origin = frontend_origin
    render layout: 'site_editor'
  end

  # PATCH /site_editor  { values: { key => value } }
  def update
    raw = params.require(:values).permit!.to_h
    errors = SiteContent.save_content_values(raw)
    if errors.empty?
      render json: { ok: true, values: SiteContent.content_values, saved_at: Time.current.in_time_zone('Asia/Ho_Chi_Minh').strftime('%H:%M:%S') }
    else
      render json: { ok: false, errors: errors }, status: :unprocessable_entity
    end
  end

  # POST /site_editor/upload  (file, kind=image|video) → { ok, url }
  # File lưu bằng Active Storage (giống video dọc của dự án); URL trả về dùng thẳng trên website.
  def upload
    rule = UPLOAD_RULES[params[:kind].to_s]
    file = params[:file]
    return upload_error('Loại file không hợp lệ.') unless rule
    return upload_error('Chưa chọn file.') unless file.respond_to?(:tempfile)

    # Nhận diện theo nội dung thật của file (không tin đuôi file)
    content_type = Marcel::MimeType.for(file.tempfile)
    return upload_error("Chỉ nhận #{rule[:label]} (file này là #{content_type}).") unless rule[:types].include?(content_type)
    return upload_error("File quá lớn — tối đa #{rule[:max_label]}.") if file.size > rule[:max]

    blob = ActiveStorage::Blob.create_and_upload!(
      io: file.tempfile,
      filename: file.original_filename,
      content_type: content_type,
      metadata: { site_content: true }
    )
    render json: { ok: true, url: public_blob_url(blob), filename: blob.filename.to_s, content_type: content_type }
  end

  private

  def upload_error(message)
    render json: { ok: false, error: message }, status: :unprocessable_entity
  end

  def public_blob_url(blob)
    host = ENV['PUBLIC_MEDIA_HOST'].presence ||
           (Rails.env.production? ? 'https://mocproductions.com' : request.base_url)
    Rails.application.routes.url_helpers.rails_blob_url(blob, host: host)
  end

  def frontend_origin
    uri = URI.parse(ENV.fetch('FRONTEND_URL', 'http://localhost:3000'))
    port = [80, 443].include?(uri.port) ? '' : ":#{uri.port}"
    "#{uri.scheme}://#{uri.host}#{port}"
  end
end
