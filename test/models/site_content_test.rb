require 'test_helper'

class SiteContentTest < ActiveSupport::TestCase
  test 'trả về giá trị mặc định khi chưa sửa' do
    assert_equal 'ABOUT US', SiteContent.content_values['about_title']
    assert_kind_of Array, SiteContent.content_values['about_awards']
  end

  test 'mọi ô trong sơ đồ đều có key, label, where, type' do
    SiteContent.content_fields.each do |f|
      %w[key label where type].each { |attr| assert f[attr].present?, "#{f['key']} thiếu #{attr}" }
    end
    keys = SiteContent.content_fields.map { |f| f['key'] }
    assert_equal keys.uniq.size, keys.size, 'key bị trùng'
  end

  test 'lưu, chuẩn hoá và xoá khi về mặc định' do
    errors = SiteContent.save_content_values(
      'about_title' => '  Xin chào ',
      'about_awards' => "A\n\n B ",
      'about_moc_image' => 'https://drive.google.com/file/d/abc_123/view?usp=sharing',
      'about_press' => { '0' => { 'name' => 'X', 'url' => 'https://x.vn' }, '1' => { 'name' => '', 'url' => '' } }
    )
    assert_empty errors
    values = SiteContent.content_values
    assert_equal 'Xin chào', values['about_title']
    assert_equal %w[A B], values['about_awards']
    assert_equal 'https://lh3.googleusercontent.com/d/abc_123', values['about_moc_image']
    assert_equal [{ 'name' => 'X', 'url' => 'https://x.vn' }], values['about_press']

    SiteContent.save_content_values('about_title' => '')
    assert_equal 'ABOUT US', SiteContent.content_values['about_title']
    assert_not SiteContent.exists?(key: 'about_title')
  end

  test 'báo lỗi theo từng ô và không lưu gì khi có lỗi' do
    errors = SiteContent.save_content_values('about_title' => 'Mới', 'social_facebook' => 'facebook.com/abc')
    assert_equal ['social_facebook'], errors.map { |e| e[:key] }
    assert_not SiteContent.exists?(key: 'about_title')
  end

  test 'API cũ site_settings vẫn có link mạng xã hội' do
    assert_equal SiteContent.content_values['social_facebook'], SiteSetting.all['footer_facebook']
  end

  test 'ảnh, video, dự án, bật/tắt' do
    project = Project.create!(name: "Test #{SecureRandom.hex(3)}")
    errors = SiteContent.save_content_values(
      'hero_images' => ['https://a.com/1.jpg', '', 'https://drive.google.com/file/d/xyz/view'],
      'hero_video' => '/rails/active_storage/blobs/redirect/abc/clip.mp4',
      'featured_project_ids' => [project.id.to_s, '999999'],
      'footer_show_video' => false
    )
    assert_empty errors
    values = SiteContent.content_values
    assert_equal ['https://a.com/1.jpg', 'https://lh3.googleusercontent.com/d/xyz'], values['hero_images']
    assert_equal [project.id], values['featured_project_ids']
    assert_equal false, values['footer_show_video']

    errors = SiteContent.save_content_values('footer_video' => 'https://youtu.be/abc', 'hero_images' => Array.new(9) { |i| "https://a.com/#{i}.jpg" })
    assert_equal %w[footer_video hero_images], errors.map { |e| e[:key] }.sort
  end
end
