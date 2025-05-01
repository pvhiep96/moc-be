module ApplicationHelper
  def link_to_add_association(name, form, association, html_options = {})
    new_object = form.object.send(association).klass.new
    id = new_object.object_id
    fields = form.fields_for(association, new_object, child_index: id) do |builder|
      render(association.to_s.singularize + '_fields', f: builder)
    end

    html_options[:class] = [html_options[:class], 'add_fields'].compact.join(' ')
    html_options[:data] ||= {}
    html_options[:data][:id] = id
    html_options[:data][:fields] = fields.gsub("\n", '')

    # Lấy data attributes từ options và gán trực tiếp
    if html_options[:data][:association_insertion_node]
      html_options['data-association-insertion-node'] = html_options[:data][:association_insertion_node]
    end

    if html_options[:data][:association_insertion_method]
      html_options['data-association-insertion-method'] = html_options[:data][:association_insertion_method]
    end

    link_to(name, '#', html_options)
  end

  def link_to_remove_association(name, f, html_options = {})
    html_options[:class] = [html_options[:class], 'remove_fields'].compact.join(' ')
    f.hidden_field(:_destroy) + link_to(name, '#', html_options)
  end

  def youtube_url(video_id)
    return video_id if video_id.start_with?('http://', 'https://')

    "https://www.youtube.com/watch?v=#{video_id}"
  end
end
