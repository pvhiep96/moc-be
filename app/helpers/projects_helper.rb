module ProjectsHelper
  YOUTUBE_ID_REGEX = %r{(?:youtube\.com/(?:[^/]+/.+/|(?:v|e(?:mbed)?)/|shorts/|.*[?&]v=)|youtu\.be/)([^"&?/\s]{11})}
  GDRIVE_FILE_ID_REGEX = %r{drive\.google\.com/file/d/([a-zA-Z0-9_-]+)}

  def youtube_video_id(url)
    return nil if url.blank?

    url.match(YOUTUBE_ID_REGEX)&.captures&.first
  end

  def gdrive_video_id(url)
    return nil if url.blank?

    url.match(GDRIVE_FILE_ID_REGEX)&.captures&.first
  end

  def youtube_thumbnail_url(url)
    if (video_id = youtube_video_id(url))
      "https://img.youtube.com/vi/#{video_id}/mqdefault.jpg"
    elsif (drive_id = gdrive_video_id(url))
      "https://lh3.googleusercontent.com/d/#{drive_id}=w480"
    end
  end

  def google_drive_folder_url(drive_id)
    "https://drive.google.com/drive/folders/#{drive_id}"
  end

  def frontend_url(path = '/')
    base = ENV.fetch('FRONTEND_URL', 'http://localhost:3000').sub(%r{/+\z}, '')
    normalized_path = path.to_s.start_with?('/') ? path : "/#{path}"
    "#{base}#{normalized_path}"
  end

  # Nội dung xác nhận trước khi xóa dự án — liệt kê rõ những gì sẽ mất
  def delete_project_confirm(project)
    "Xóa vĩnh viễn dự án \"#{project.name}\"?\n\n" \
      "Toàn bộ nội dung sẽ bị xóa và KHÔNG thể khôi phục:\n" \
      "- #{project.project_images.size} ảnh\n" \
      "- #{project.video_urls.size} video ngang\n" \
      "- #{project.descriptions.size} mô tả"
  end
end
