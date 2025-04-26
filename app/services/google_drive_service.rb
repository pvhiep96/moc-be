require 'google/apis/drive_v3'
require 'googleauth'
require 'json'

class GoogleDriveService
  attr_reader :drive

  def initialize
    @drive = Google::Apis::DriveV3::DriveService.new
    @drive.authorization = authorize
  end

  def get_image_urls(folder_id)
    image_urls = []
    
    begin
      Rails.logger.info("Fetching images from Google Drive folder: #{folder_id}")
      
      # Get all files in the folder
      files = @drive.list_files(q: "'#{folder_id}' in parents and trashed = false",
                              fields: 'files(id, name, mimeType)')
      
      Rails.logger.info("Found #{files.files.count} files in folder")
      
      # Sort files by name to ensure consistent order
      sorted_files = files.files.sort_by(&:name)
      
      # Process each file
      sorted_files.each do |file|
        # Check if the file is an image
        if file.mime_type.start_with?('image/')
          # Use direct link to the image (this format works well with Next.js)
          image_url = "https://lh3.googleusercontent.com/d/#{file.id}"
          Rails.logger.info("Adding image: #{file.name} with URL: #{image_url}")
          image_urls << image_url
          
          # Stop after reaching the limit
        else
          Rails.logger.info("Skipping non-image file: #{file.name} (#{file.mime_type})")
        end
      end
      
      if image_urls.empty?
        Rails.logger.warn("No images found in Google Drive folder: #{folder_id}")
      end
    rescue Google::Apis::Error => e
      Rails.logger.error("Google Drive API error: #{e.message}")
      # Return empty array for now, but could raise if needed
    end
    
    image_urls
  end

  private

  def authorize
    credentials_path = Rails.root.join('credentials.json')
    Rails.logger.info("Using credentials file at: #{credentials_path}")
    
    # Check if file exists
    unless File.exist?(credentials_path)
      error_msg = "Credentials file not found at #{credentials_path}"
      Rails.logger.error(error_msg)
      raise error_msg
    end
    
    # Check if file is valid JSON
    begin
      credentials_content = File.read(credentials_path)
      JSON.parse(credentials_content)
      Rails.logger.info("Credentials JSON is valid")
    rescue JSON::ParserError => e
      error_msg = "Invalid JSON in credentials file: #{e.message}"
      Rails.logger.error(error_msg)
      raise error_msg
    end
    
    # Use the credentials.json file for authentication
    Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(credentials_path),
      scope: Google::Apis::DriveV3::AUTH_DRIVE_READONLY
    )
  rescue => e
    Rails.logger.error("Google Drive authentication error: #{e.message}")
    raise "Failed to authenticate with Google Drive: #{e.message}"
  end
end 