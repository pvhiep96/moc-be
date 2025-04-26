GrapeSwaggerRails.options.url = '/api/swagger_doc'
GrapeSwaggerRails.options.app_name = 'Project Management API'
GrapeSwaggerRails.options.app_url = '/'
GrapeSwaggerRails.options.doc_expansion = 'list'

GrapeSwaggerRails.options.before_action do
  GrapeSwaggerRails.options.api_auth = 'basic'
  GrapeSwaggerRails.options.api_key_name = 'Authorization'
  GrapeSwaggerRails.options.api_key_type = 'header'

  unless Rails.env.test?
    authenticate_or_request_with_http_basic('Application') do |name, password|
      name == ENV['SWAGGER_USER'] && password == ENV['SWAGGER_PASSWORD']
    end
  end

  GrapeSwaggerRails.options.app_url = request.protocol + request.host_with_port
end
