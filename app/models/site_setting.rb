# Lớp tương thích cho API cũ GET /api/v1/projects/site_settings.
# Nội dung thật nằm ở SiteContent (config/site_content.yml + bảng site_contents).
class SiteSetting
  def self.all
    values = SiteContent.content_values
    home_keys = SiteContent.content_pages.find { |p| p['id'] == 'home' }['sections'].flat_map { |s| s['fields'].map { |f| f['key'] } }
    result = values.slice(*home_keys)
    SiteContent::LEGACY_KEY_MAP.each { |old_key, new_key| result[old_key] = values[new_key] }
    result
  end
end
