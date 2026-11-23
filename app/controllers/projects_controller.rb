class ProjectsController < ApplicationController
  before_action :require_admin
  before_action :set_project,
                only: %i[show edit update destroy reload_images toggle_video display_all_content
                         manage_content update_content content_item update_content_positions
                         quick_set_studio_media]

  PRELOAD_SCOPE = [
    :video_urls,
    :descriptions,
    :project_images,
    { video_vertical: { video_file_attachment: :blob } },
    { content_positions: :positionable }
  ].freeze

  def index
    base_scope = Project.includes(*PRELOAD_SCOPE)

    # Thống kê tổng quan trên Dashboard
    @stats = {
      total_projects: Project.count,
      total_images: ProjectImage.count,
      displayed_images: ContentPosition.where(positionable_type: 'ProjectImage').count,
      with_vertical_video: Project.where(show_video: true).count,
      total_inquiries: Inquiry.count
    }

    @projects = base_scope.order(id: :desc)
    @projects = @projects.where('name ILIKE :q OR drive_id ILIKE :q', q: "%#{params[:q]}%") if params[:q].present?

    case params[:filter]
    when 'video_on'
      @projects = @projects.where(show_video: true)
    when 'no_displayed'
      displayed_project_ids = ContentPosition.where(positionable_type: 'ProjectImage').select(:project_id).distinct
      @projects = @projects.where.not(id: displayed_project_ids)
    end

    @projects = @projects.page(params[:page]).per(12)
  end

  # Trang HOME giờ được sửa trực quan trong "Sửa giao diện website" (SiteEditorController)
  def home_manager
    redirect_to site_editor_path(page: 'home')
  end

  def update_home_settings
    redirect_to site_editor_path(page: 'home')
  end

  def reset_home_settings
    redirect_to site_editor_path(page: 'home')
  end

  # =========================================================================
  # TRANG 2: QUẢN LÝ TRANG STUDIO (/studio) — KÈM DEMO LƯỚI THẺ DỰ ÁN
  # =========================================================================
  def studio_manager
    @projects = Project.includes(*PRELOAD_SCOPE).order(id: :desc)
    selected_id = params[:project_id].presence
    @selected_project = if selected_id
                          @projects.find { |p| p.id == selected_id.to_i } || @projects.first
                        else
                          @projects.first
                        end
    @selected_project&.build_video_vertical if @selected_project && @selected_project.video_vertical.nil?
  end

  # Đặt nhanh Ảnh Bìa (#1) hoặc Ảnh Hover (#2) cho dự án ngay từ trang quản lý Studio / Home
  def quick_set_studio_media
    role = params[:role].to_s # 'cover' (vị trí ảnh #1) hoặc 'hover' (vị trí ảnh #2)
    image_id = params[:image_id].to_i
    img = @project.project_images.find_by(id: image_id)

    unless img
      redirect_back fallback_location: studio_manager_projects_path(project_id: @project.id),
                    alert: 'Không tìm thấy ảnh này trong dự án.'
      return
    end

    ActiveRecord::Base.transaction do
      ordered = @project.content_positions.order(:position).map do |cp|
        { type: cp.positionable_type, id: cp.positionable_id }
      end

      # Loại bỏ ảnh vừa chọn khỏi vị trí cũ (nếu có)
      ordered.reject! { |item| item[:type] == 'ProjectImage' && item[:id] == img.id }

      image_indices = ordered.each_index.select { |idx| ordered[idx][:type] == 'ProjectImage' }

      if role == 'hover'
        if image_indices.empty?
          ordered << { type: 'ProjectImage', id: img.id }
        elsif image_indices.size == 1
          ordered.insert(image_indices[0] + 1, { type: 'ProjectImage', id: img.id })
        else
          ordered.insert(image_indices[1], { type: 'ProjectImage', id: img.id })
        end
      else
        # Mặc định: đặt làm Ảnh Bìa Chính (ảnh đầu tiên)
        if image_indices.empty?
          ordered.unshift({ type: 'ProjectImage', id: img.id })
        else
          ordered.insert(image_indices[0], { type: 'ProjectImage', id: img.id })
        end
      end

      @project.content_positions.destroy_all
      ordered.each_with_index do |item, index|
        @project.content_positions.create!(
          positionable_type: item[:type],
          positionable_id: item[:id],
          position: index + 1
        )
      end
    end

    role_label = role == 'hover' ? '✦ Ảnh Hover (#2)' : '★ Ảnh Bìa Chính (#1)'
    redirect_back fallback_location: studio_manager_projects_path(project_id: @project.id),
                  notice: "Đã đặt #{role_label} cho dự án \"#{@project.name}\" thành công!"
  end

  # =========================================================================
  # TRANG 3: QUẢN LÝ TRANG CHI TIẾT PROJECT (/projects/[id])
  # =========================================================================
  def detail_manager
    target = if params[:project_id].present?
               Project.find_by(id: params[:project_id])
             else
               Project.order(id: :desc).first
             end

    if target
      redirect_to edit_project_path(target, section: params[:section])
    else
      redirect_to new_project_path
    end
  end

  def show
    load_workspace_data
    build_missing_nested_records
    render :edit
  end

  def new
    @project = Project.new(auto_display_new_content: true)
    @project.video_urls.build
    @project.build_video_vertical
    @project.descriptions.build
  end

  def create
    @project = Project.new(project_params)

    if @project.save
      apply_content_order_json if params[:content_order_json].present?
      set_drive_sync_flash
      redirect_to edit_project_path(@project), notice: "Đã tạo dự án \"#{@project.name}\" thành công. Bạn có thể kiểm tra và kéo thả nội dung ngay bên dưới."
    else
      build_missing_nested_records
      log_validation_errors
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @all_projects = Project.order(id: :desc)
    load_workspace_data
    build_missing_nested_records
  end

  def update
    if @project.update(project_params)
      apply_content_order_json if params[:content_order_json].present?
      set_drive_sync_flash
      target_url = params[:return_to].presence || edit_project_path(@project, section: params[:active_section])
      redirect_to target_url, notice: "Đã lưu thay đổi dự án \"#{@project.name}\" thành công."
    else
      @all_projects = Project.order(id: :desc)
      load_workspace_data
      build_missing_nested_records
      log_validation_errors
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @project.name
    @project.destroy
    redirect_to projects_url, notice: "Đã xóa vĩnh viễn dự án \"#{name}\"."
  end

  def reload_images
    prune = params[:prune_removed] == '1'
    @project.reload_images(prune_removed: prune)

    if @project.drive_sync_failed?
      flash[:warning] = 'Không lấy được ảnh nào từ Google Drive. Hãy kiểm tra lại đường link/Drive ID ' \
                        'và đảm bảo thư mục đã được chia sẻ quyền xem.'
    else
      parts = ["tìm thấy #{@project.drive_sync_count} ảnh"]
      parts << "thêm mới #{@project.drive_added_count} ảnh (đã tự động đưa lên hiển thị)" if @project.drive_added_count.to_i.positive?
      parts << "đã dọn #{@project.drive_removed_count} ảnh cũ" if @project.drive_removed_count.to_i.positive?
      parts << 'không có ảnh mới' if @project.drive_added_count.to_i.zero? && @project.drive_removed_count.to_i.zero?
      flash[:notice] = "Đồng bộ Google Drive hoàn tất (#{parts.join(', ')})."
    end

    redirect_back fallback_location: edit_project_path(@project)
  end

  def toggle_video
    @project.update_column(:show_video, !@project.show_video)
    state_text = @project.show_video ? 'Đã BẬT' : 'Đã TẮT'
    redirect_back fallback_location: projects_path,
                  notice: "#{state_text} hiển thị video dọc cho dự án \"#{@project.name}\"."
  end

  def display_all_content
    only_type = params[:only_type].presence
    @project.display_all_content!(only_type: only_type)
    redirect_to edit_project_path(@project, anchor: 'content-studio'),
                notice: 'Đã đưa toàn bộ nội dung vào danh sách hiển thị trên website.'
  end

  # Giữ tương thích với route manage_content cũ → hiển thị thẳng màn hình All-in-One
  def manage_content
    load_workspace_data
    build_missing_nested_records
    render :edit
  end

  # Action để cập nhật thứ tự hiển thị của tất cả nội dung (form truyền thống)
  def update_content
    content_order = params[:content_order] || []

    ActiveRecord::Base.transaction do
      @project.content_positions.destroy_all

      content_order.each_with_index do |content_item, index|
        type, id = content_item.split('-')

        @project.content_positions.create!(
          positionable_type: type,
          positionable_id: id,
          position: index
        )
      end
    end

    redirect_to edit_project_path(@project, anchor: 'content-studio'),
                notice: 'Thứ tự hiển thị nội dung đã được cập nhật thành công.'
  rescue ActiveRecord::RecordInvalid => e
    redirect_to edit_project_path(@project, anchor: 'content-studio'),
                alert: "Lỗi khi cập nhật thứ tự hiển thị: #{e.message}"
  end

  # Action để cập nhật content_position khi kéo thả / bấm chọn (AJAX)
  def update_content_positions
    positions = params[:positions] || []

    ActiveRecord::Base.transaction do
      @project.content_positions.destroy_all

      positions.each_with_index do |position_data, idx|
        @project.content_positions.create!(
          positionable_type: position_data[:type],
          positionable_id: position_data[:id],
          position: position_data[:position] || (idx + 1)
        )
      end
    end

    render json: {
      success: true,
      message: 'Đã lưu thứ tự hiển thị',
      displayed_count: positions.size,
      positions: positions
    }
  rescue ActiveRecord::RecordInvalid => e
    render json: {
      success: false,
      error: "Lỗi khi cập nhật thứ tự: #{e.message}"
    }, status: :unprocessable_entity
  rescue StandardError => e
    render json: {
      success: false,
      error: "Lỗi không xác định: #{e.message}"
    }, status: :internal_server_error
  end

  def content_item
    content_type = params[:type]
    content_id = params[:id]

    case content_type
    when 'ProjectImage'
      item = @project.project_images.find(content_id)
      render json: { id: item.id, image_url: item.image_url }
    when 'Description'
      item = @project.descriptions.find(content_id)
      render json: { id: item.id, content: item.content }
    when 'VideoUrl'
      item = @project.video_urls.find(content_id)
      render json: { id: item.id, url: item.url }
    else
      render json: { error: 'Invalid content type' }, status: :bad_request
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Content item not found' }, status: :not_found
  end

  private

  def set_project
    @project = Project.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to projects_path, alert: 'Dự án không tồn tại.'
  end

  def load_workspace_data
    ordered_content_positions = @project.content_positions.includes(:positionable).order(:position)

    @content_items = ordered_content_positions.filter_map do |position|
      next unless position.positionable

      {
        id: position.positionable_id,
        type: position.positionable_type,
        content: position.positionable
      }
    end

    ordered_image_ids = @project.content_positions.where(positionable_type: 'ProjectImage').pluck(:positionable_id)
    ordered_description_ids = @project.content_positions.where(positionable_type: 'Description').pluck(:positionable_id)
    ordered_video_ids = @project.content_positions.where(positionable_type: 'VideoUrl').pluck(:positionable_id)

    @unordered_images = @project.project_images.where.not(id: ordered_image_ids).order(:id)
    @unordered_descriptions = @project.descriptions.where.not(id: ordered_description_ids).order(:id)
    @unordered_videos = @project.video_urls.where.not(id: ordered_video_ids).order(:id)
  end

  def apply_content_order_json
    parsed = JSON.parse(params[:content_order_json])
    return unless parsed.is_a?(Array)

    ActiveRecord::Base.transaction do
      @project.content_positions.destroy_all
      parsed.each_with_index do |item, index|
        type = item['type'] || item[:type]
        id = item['id'] || item[:id]
        next if type.blank? || id.blank?

        @project.content_positions.create!(
          positionable_type: type,
          positionable_id: id,
          position: index + 1
        )
      end
    end
  rescue JSON::ParserError, ActiveRecord::RecordInvalid => e
    Rails.logger.warn("Could not apply content_order_json: #{e.message}")
  end

  def set_drive_sync_flash
    return if @project.drive_id.blank?

    if @project.drive_sync_failed?
      flash[:warning] = 'Dự án đã lưu nhưng KHÔNG lấy được ảnh nào từ Google Drive. ' \
                        'Hãy kiểm tra lại đường link/Drive ID và đảm bảo thư mục đã được chia sẻ quyền xem.'
    elsif @project.drive_added_count.to_i.positive?
      flash[:info] = "Đã đồng bộ #{@project.drive_sync_count} ảnh từ Google Drive (thêm mới #{@project.drive_added_count} ảnh và tự động hiển thị)."
    else
      flash[:info] = "Đã đồng bộ #{@project.drive_sync_count} ảnh từ Google Drive."
    end
  end

  def build_missing_nested_records
    @project.video_urls.build if @project.video_urls.empty?
    @project.build_video_vertical if @project.video_vertical.nil?
    @project.descriptions.build if @project.descriptions.empty?
  end

  def log_validation_errors
    Rails.logger.debug("Project validation errors: #{@project.errors.full_messages}")
    return if @project.video_vertical&.errors.blank?

    Rails.logger.debug("Video vertical errors: #{@project.video_vertical.errors.full_messages}")
  end

  def project_params
    params.require(:project).permit(
      :name,
      :drive_id,
      :show_video,
      :auto_display_new_content,
      video_urls_attributes: %i[id url _destroy],
      video_vertical_attributes: %i[id url video_file _destroy],
      descriptions_attributes: %i[id content position_display _destroy]
    )
  end

  def require_admin
    return if admin_logged_in?

    redirect_to login_path, alert: 'Bạn cần đăng nhập để thực hiện thao tác này.'
  end
end
