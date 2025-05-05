# Configure ActiveStorage URL generation
Rails.application.config.after_initialize do
  # Set default URL options for ActiveStorage
  if Rails.env.production?
    ActiveStorage::Current.url_options = {
      host: 'http://47.129.243.193:3006',
      protocol: 'http'
    }
  end
end
