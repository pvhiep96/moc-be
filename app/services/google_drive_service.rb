require 'google/apis/drive_v3'
require 'googleauth'
require 'json'
require 'stringio'
require 'rexml/document'

class GoogleDriveService
  FOLDER_MIME = 'application/vnd.google-apps.folder'.freeze
  DOCX_MIME = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'.freeze
  MAX_DEPTH = 4

  attr_reader :drive

  def initialize
    @drive = Google::Apis::DriveV3::DriveService.new
    @drive.authorization = authorize
  end

  # Lấy toàn bộ nội dung trong folder_id (duyệt đệ quy cả các thư mục con như PHOTO, VIDEO...):
  # - images: mảng URL ảnh https://lh3.googleusercontent.com/d/<id>
  # - videos: mảng { id:, name:, url: "https://drive.google.com/file/d/<id>/preview" }
  # - descriptions: mảng HTML trích xuất từ file .docx trong thư mục (ví dụ CREDIT.docx)
  def get_folder_contents(folder_id)
    image_files = []
    video_files = []
    docx_files = []

    collect_files_recursively(folder_id, depth: 0) do |file|
      mime = file.mime_type.to_s
      if mime.start_with?('image/')
        image_files << file
      elsif mime.start_with?('video/')
        video_files << file
      elsif mime == DOCX_MIME
        docx_files << file
      end
    end

    descriptions = docx_files.filter_map do |docx_file|
      extract_docx_html(docx_file.id, docx_file.name)
    end

    {
      images: image_files.map { |f| "https://lh3.googleusercontent.com/d/#{f.id}" },
      videos: video_files.map do |f|
        {
          id: f.id,
          name: f.name,
          url: "https://drive.google.com/file/d/#{f.id}/preview"
        }
      end,
      descriptions: descriptions
    }
  rescue Google::Apis::Error => e
    Rails.logger.error("Google Drive API error: #{e.message}")
    { images: [], videos: [], descriptions: [] }
  end

  # Giữ hàm cũ tương thích ngược: trả về danh sách URL ảnh
  def get_image_urls(folder_id)
    get_folder_contents(folder_id)[:images]
  end

  # Liệt kê toàn bộ cây thư mục
  def list_folder_tree(folder_id, depth: 0)
    return [] if depth > MAX_DEPTH

    response = @drive.list_files(
      q: "'#{folder_id}' in parents and trashed = false",
      fields: 'files(id, name, mimeType, size)',
      page_size: 1000
    )
    files = (response.files || []).sort_by { |f| f.name.to_s.downcase }
    result = []

    files.each do |file|
      entry = {
        id: file.id,
        name: file.name,
        mime_type: file.mime_type,
        size: file.size,
        depth: depth
      }
      result << entry
      if file.mime_type == FOLDER_MIME
        result.concat(list_folder_tree(file.id, depth: depth + 1))
      end
    end

    result
  end

  private

  def collect_files_recursively(folder_id, depth: 0, &block)
    return if depth > MAX_DEPTH

    Rails.logger.info("Fetching files from Google Drive folder: #{folder_id} (depth #{depth})")
    page_token = nil

    loop do
      response = @drive.list_files(
        q: "'#{folder_id}' in parents and trashed = false",
        fields: 'nextPageToken, files(id, name, mimeType)',
        page_size: 500,
        page_token: page_token
      )

      files = (response.files || []).sort_by { |f| f.name.to_s.downcase }

      subfolders = []
      files.each do |file|
        if file.mime_type == FOLDER_MIME
          subfolders << file
        else
          yield(file)
        end
      end

      subfolders.each do |subfolder|
        collect_files_recursively(subfolder.id, depth: depth + 1, &block)
      end

      page_token = response.next_page_token
      break if page_token.blank?
    end
  end

  # Tải file .docx từ Google Drive và đọc word/document.xml thành các đoạn <p>
  def extract_docx_html(file_id, file_name)
    buffer = StringIO.new
    @drive.get_file(file_id, download_dest: buffer)
    buffer.rewind

    # Giải nén word/document.xml bằng lệnh unzip từ stdin hoặc file tạm
    Tempfile.create(['drive_doc', '.docx'], binmode: true) do |tmp|
      tmp.write(buffer.string)
      tmp.flush
      xml_content = IO.popen(['unzip', '-p', tmp.path, 'word/document.xml'], err: [:child, :out], &:read)
      return nil if xml_content.blank? || !$?.success?

      doc = REXML::Document.new(xml_content)
      paragraphs = []
      doc.elements.each('//w:p') do |p_node|
        texts = []
        p_node.elements.each('.//w:t') { |t_node| texts << t_node.text.to_s }
        line = texts.join.strip
        paragraphs << ERB::Util.html_escape(line) if line.present?
      end

      return nil if paragraphs.empty?

      paragraphs.map { |p| "<p>#{p}</p>" }.join("\n")
    end
  rescue StandardError => e
    Rails.logger.warn("Could not parse docx #{file_name} (#{file_id}): #{e.message}")
    nil
  end

  def authorize
    credentials_path = Rails.root.join('credentials.json')
    Rails.logger.info("Using credentials file at: #{credentials_path}")

    unless File.exist?(credentials_path)
      error_msg = "Credentials file not found at #{credentials_path}"
      Rails.logger.error(error_msg)
      raise error_msg
    end

    begin
      credentials_content = File.read(credentials_path)
      JSON.parse(credentials_content)
    rescue JSON::ParserError => e
      error_msg = "Invalid JSON in credentials file: #{e.message}"
      Rails.logger.error(error_msg)
      raise error_msg
    end

    Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(credentials_path),
      scope: Google::Apis::DriveV3::AUTH_DRIVE_READONLY
    )
  rescue StandardError => e
    Rails.logger.error("Google Drive authentication error: #{e.message}")
    raise "Failed to authenticate with Google Drive: #{e.message}"
  end
end
