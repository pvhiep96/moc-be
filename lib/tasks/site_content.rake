namespace :site_content do
  desc 'Xuất giá trị mặc định (config/site_content.yml) sang moc-fe để FE có dữ liệu dự phòng khi API lỗi'
  task :export_defaults do
    require 'yaml'
    require 'json'
    schema = YAML.safe_load_file(File.expand_path('../../config/site_content.yml', __dir__))
    defaults = schema['pages'].flat_map { |p| p['sections'].flat_map { |s| s['fields'] } }
                              .to_h { |f| [f['key'], f['default']] }
    out = ENV.fetch('OUT', File.expand_path('../../../moc-fe/src/content/site-content-defaults.json', __dir__))
    File.write(out, "#{JSON.pretty_generate(defaults)}\n")
    puts "Đã ghi #{defaults.size} giá trị mặc định → #{out}"
  end
end
