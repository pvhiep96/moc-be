require 'google/apis/drive_v3'

# Configure Google API
Google::Apis.logger = Rails.logger
Google::Apis::ClientOptions.default.application_name = "MOC Studio"
Google::Apis::ClientOptions.default.application_version = "1.0.0"

# Verify credentials file exists
unless File.exist?(Rails.root.join('credentials.json'))
  Rails.logger.warn "Google API credentials file not found at #{Rails.root.join('credentials.json')}. Google Drive functionality may not work."
end 