class ProjectsController < ApplicationController
  before_action :require_admin
  before_action :set_project,
                only: %i[show edit update destroy reload_images manage_content
                         update_content content_item update_content_positions]

  def index
    @projects = Project.all
  end

  def show
    return if admin_logged_in?

    redirect_to login_path, alert: 'Bạn cần đăng nhập để xem chi tiết dự án.'
    nil
  end

  def new
    @project = Project.new
    @project.video_urls.build
    @project.build_video_vertical
    @project.descriptions.build
  end

  def create
    @project = Project.new(project_params)

    if @project.save
      redirect_to @project, notice: 'Project was successfully created.'
    else
      # Ensure nested models are built for the form
      @project.video_urls.build if @project.video_urls.empty?
      @project.build_video_vertical if @project.video_vertical.nil?
      @project.descriptions.build if @project.descriptions.empty?

      # Log errors for debugging
      Rails.logger.debug("Project validation errors: #{@project.errors.full_messages}")
      if @project.video_vertical&.errors.present?
        Rails.logger.debug("Video vertical errors: #{@project.video_vertical.errors.full_messages}")
      end

      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @project.video_urls.build if @project.video_urls.empty?
    @project.build_video_vertical if @project.video_vertical.nil?
    @project.descriptions.build if @project.descriptions.empty?
  end

  def update
    if @project.update(project_params)
      redirect_to @project, notice: 'Project was successfully updated.'
    else
      # Ensure nested models are built for the form
      @project.video_urls.build if @project.video_urls.empty?
      @project.build_video_vertical if @project.video_vertical.nil?
      @project.descriptions.build if @project.descriptions.empty?

      # Log errors for debugging
      Rails.logger.debug("Project validation errors: #{@project.errors.full_messages}")
      if @project.video_vertical&.errors.present?
        Rails.logger.debug("Video vertical errors: #{@project.video_vertical.errors.full_messages}")
      end

      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @project.destroy
    redirect_to projects_url, notice: 'Project was successfully destroyed.'
  end

  def reload_images
    @project.reload_images
    redirect_to @project, notice: 'Images have been successfully reloaded from Google Drive.'
  end

  # Action để quản lý thứ tự hiển thị của tất cả nội dung
  def manage_content
    # Lấy danh sách các nội dung đã được sắp xếp
    ordered_content_positions = @project.content_positions.includes(:positionable).order(:position)

    @content_items = []
    ordered_content_positions.each do |position|
      @content_items << {
        id: position.positionable_id,
        type: position.positionable_type,
        content: position.positionable
      }
    end

    # Lấy danh sách các nội dung chưa được sắp xếp
    ordered_image_ids = @project.content_positions.where(positionable_type: 'ProjectImage').pluck(:positionable_id)
    ordered_description_ids = @project.content_positions.where(positionable_type: 'Description').pluck(:positionable_id)
    ordered_video_ids = @project.content_positions.where(positionable_type: 'VideoUrl').pluck(:positionable_id)

    @unordered_images = @project.project_images.where.not(id: ordered_image_ids)
    @unordered_descriptions = @project.descriptions.where.not(id: ordered_description_ids)
    @unordered_videos = @project.video_urls.where.not(id: ordered_video_ids)
  end

  # Action để cập nhật thứ tự hiển thị của tất cả nội dung
  def update_content
    content_order = params[:content_order] || []

    ActiveRecord::Base.transaction do
      # Xóa tất cả các content_position hiện tại
      @project.content_positions.destroy_all

      # Tạo mới các content_position dựa trên dữ liệu gửi lên
      content_order.each_with_index do |content_item, index|
        type, id = content_item.split('-')

        @project.content_positions.create!(
          positionable_type: type,
          positionable_id: id,
          position: index
        )
      end
    end

    redirect_to @project, notice: 'Thứ tự hiển thị nội dung đã được cập nhật thành công.'
  rescue ActiveRecord::RecordInvalid => e
    # Xử lý lỗi validation
    redirect_to manage_content_project_path(@project), alert: "Lỗi khi cập nhật thứ tự hiển thị: #{e.message}"
  end

  # Action để cập nhật content_position khi kéo thả (AJAX)
  def update_content_positions
    positions = params[:positions] || []

    ActiveRecord::Base.transaction do
      # Xóa tất cả content_positions hiện tại để tránh conflict
      @project.content_positions.destroy_all

      # Tạo lại content_positions với thứ tự mới
      positions.each do |position_data|
        @project.content_positions.create!(
          positionable_type: position_data[:type],
          positionable_id: position_data[:id],
          position: position_data[:position]
        )
      end
    end

    render json: {
      success: true,
      message: 'Thứ tự đã được cập nhật thành công',
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

  # Action để lấy thông tin của một content item
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

  def project_params
    params.require(:project).permit(
      :name,
      :drive_id,
      :show_video,
      video_urls_attributes: %i[id url _destroy],
      video_vertical_attributes: %i[id url video_file _destroy],
      descriptions_attributes: %i[id content position_display _destroy]
    )
  end

  def require_admin
    return if admin_logged_in?

    redirect_to login_path, alert: 'Bạn cần đăng nhập để thực hiện hành động này.'
  end
end
