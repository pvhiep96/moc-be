# Nội dung chữ / link / ảnh hiển thị trên website công khai (moc-fe).
#
# - Sơ đồ (trang → khu vực → ô nhập, kèm mô tả vị trí) nằm ở config/site_content.yml.
# - Bảng site_contents chỉ lưu những ô đã được sửa khác giá trị mặc định.
class SiteContent < ApplicationRecord
  SCHEMA_PATH = Rails.root.join('config', 'site_content.yml')
  LEGACY_JSON_PATH = Rails.root.join('config', 'site_settings.json')
  # Key cũ của SiteSetting → key mới (link mạng xã hội giờ dùng chung toàn site)
  LEGACY_KEY_MAP = {
    'footer_facebook' => 'social_facebook',
    'footer_instagram' => 'social_instagram',
    'footer_youtube' => 'social_youtube'
  }.freeze

  validates :key, presence: true, uniqueness: true

  class << self
    def content_schema
      if Rails.env.development?
        # Dev: đọc lại mỗi lần để sửa YAML là thấy ngay
        read_content_schema_file
      else
        @content_schema ||= read_content_schema_file
      end
    end

    def content_pages
      content_schema.fetch('pages')
    end

    def content_fields
      content_pages.flat_map { |p| p['sections'].flat_map { |s| s['fields'] } }
    end

    def content_field(key)
      content_fields_by_key[key.to_s]
    end

    def content_fields_by_key
      content_fields.index_by { |f| f['key'] }
    end

    def content_defaults
      content_fields.to_h { |f| [f['key'], f['default']] }
    end

    # Giá trị hiện tại của toàn bộ website (mặc định + phần đã sửa)
    def content_values
      import_legacy_settings!
      saved = where(key: content_fields_by_key.keys).pluck(:key, :value).to_h
      content_defaults.merge(saved.compact)
    end

    # Lưu nhiều ô cùng lúc. Trả về danh sách lỗi [{ key:, message: }] (rỗng nếu thành công).
    def save_content_values(raw_values)
      errors = []
      known = content_fields_by_key
      transaction do
        raw_values.to_h.each do |key, raw|
          definition = known[key.to_s]
          next unless definition

          value = cast_content(definition, raw)
          if value.nil? || value == definition['default']
            where(key: key).delete_all
          else
            record = find_or_initialize_by(key: key)
            record.value = value
            record.save!
          end
        rescue ArgumentError => e
          errors << { key: key.to_s, message: "#{definition['label']}: #{e.message}" }
        end
        raise ActiveRecord::Rollback if errors.any?
      end
      errors
    end

    def reset_content_keys(keys)
      where(key: Array(keys).map(&:to_s)).delete_all
    end

    # Chuẩn hoá giá trị theo kiểu ô nhập; trả nil nếu rỗng (→ dùng mặc định)
    def cast_content(definition, raw)
      case definition['type']
      when 'lines'
        list = raw.is_a?(Array) ? raw : raw.to_s.split(/\r?\n/)
        list = list.map { |l| l.to_s.strip }.reject(&:empty?)
        list.presence
      when 'list'
        items = raw.is_a?(Hash) ? raw.values : Array(raw)
        items = items.map { |item| cast_item(definition, item) }.compact
        items.presence
      when 'image'
        normalize_image_url(raw.to_s.strip).presence
      when 'images'
        list = raw.is_a?(Hash) ? raw.values : Array(raw)
        list = list.map { |u| normalize_image_url(u.to_s.strip) }.reject(&:blank?).uniq
        raise ArgumentError, "tối đa #{definition['max']} ảnh" if definition['max'] && list.size > definition['max']

        list.presence
      when 'video'
        normalize_video_url(raw.to_s.strip).presence
      when 'projects'
        ids = (raw.is_a?(Hash) ? raw.values : Array(raw)).map(&:to_i).select(&:positive?).uniq
        ids &= Project.where(id: ids).pluck(:id) # bỏ dự án đã bị xoá, giữ thứ tự đã chọn
        raise ArgumentError, "chọn tối đa #{definition['max']} dự án" if definition['max'] && ids.size > definition['max']

        ids.presence
      when 'boolean'
        ActiveModel::Type::Boolean.new.cast(raw)
      when 'url'
        url = raw.to_s.strip
        raise ArgumentError, 'link phải bắt đầu bằng http:// hoặc https://' if url.present? && url !~ %r{\Ahttps?://}i

        url.presence
      when 'email'
        email = raw.to_s.strip
        raise ArgumentError, 'email không hợp lệ' if email.present? && email !~ URI::MailTo::EMAIL_REGEXP

        email.presence
      else
        text = raw.to_s.gsub("\r\n", "\n").strip
        text.presence
      end
    end

    # Link chia sẻ file Google Drive → link ảnh trực tiếp (giống ảnh dự án)
    def normalize_image_url(url)
      return url if url.blank?

      if (m = url.match(%r{drive\.google\.com/file/d/([\w-]+)}) || url.match(%r{drive\.google\.com/(?:open|uc)\?(?:.*&)?id=([\w-]+)}))
        return "https://lh3.googleusercontent.com/d/#{m[1]}"
      end
      raise ArgumentError, 'ảnh phải là link http(s) hoặc đường dẫn bắt đầu bằng /' unless url =~ %r{\A(https?://|/)}i

      url
    end

    # Video nền phát bằng thẻ <video> → phải là file video trực tiếp (upload hoặc link .mp4)
    def normalize_video_url(url)
      return url if url.blank?
      if url =~ %r{youtube\.com|youtu\.be|drive\.google\.com}i
        raise ArgumentError, 'không dùng được link YouTube / Google Drive — hãy tải file video lên (mp4, webm, mov)'
      end
      raise ArgumentError, 'video phải là link http(s) hoặc đường dẫn bắt đầu bằng /' unless url =~ %r{\A(https?://|/)}i

      url
    end

    private

    def read_content_schema_file
      YAML.safe_load_file(SCHEMA_PATH, aliases: false)
    end

    def cast_item(definition, item)
      item = item.to_h.stringify_keys
      casted = definition['item_fields'].to_h do |sub|
        raw = item[sub['key']]
        value = case sub['type']
                when 'boolean' then ActiveModel::Type::Boolean.new.cast(raw) || false
                when 'lines' then cast_content({ 'type' => 'lines' }, raw) || []
                when 'url' then cast_content({ 'type' => 'url' }, raw) || ''
                else raw.to_s.strip
                end
        [sub['key'], value]
      end
      text_values = casted.values.select { |v| v.is_a?(String) }
      text_values.all?(&:empty?) ? nil : casted
    end

    # Một lần duy nhất: chuyển dữ liệu cũ của config/site_settings.json vào DB
    def import_legacy_settings!
      return if @legacy_checked
      @legacy_checked = true
      return unless File.exist?(LEGACY_JSON_PATH)

      legacy = JSON.parse(File.read(LEGACY_JSON_PATH)) rescue {}
      mapped = legacy.to_h { |k, v| [LEGACY_KEY_MAP.fetch(k, k), v] }
      mapped = mapped.reject { |k, _| exists?(key: k) }
      save_content_values(mapped)
      File.rename(LEGACY_JSON_PATH, "#{LEGACY_JSON_PATH}.imported")
      Rails.logger.info("[SiteContent] Đã chuyển #{mapped.size} giá trị từ site_settings.json vào DB")
    rescue StandardError => e
      Rails.logger.error("[SiteContent] Không chuyển được site_settings.json: #{e.message}")
    end
  end
end
