class ProjectsController < ApplicationController
  before_action :require_admin, except: %i[index show]
  before_action :set_project, only: %i[show edit update destroy reload_images manage_images update_images]

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
      render :new
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
      render :edit
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

  # Action để quản lý ảnh hiển thị
  def manage_images
    @project_images = @project.project_images

    # Lấy danh sách ID ảnh đã được chọn hiển thị
    @selected_image_ids = @project.content_positions
                                  .where(positionable_type: 'ProjectImage')
                                  .order(:position)
                                  .pluck(:positionable_id)

    # Đánh dấu các ảnh đã được chọn
    @project_images.each do |image|
      image.display = @selected_image_ids.include?(image.id)
    end
  end

  # Action để cập nhật ảnh hiển thị
  def update_images
    selected_image_ids = params[:selected_images] || []

    ActiveRecord::Base.transaction do
      # Xóa tất cả các content_position hiện tại của project cho ảnh
      @project.content_positions.where(positionable_type: 'ProjectImage').destroy_all

      # Tạo mới các content_position dựa trên dữ liệu gửi lên
      selected_image_ids.each_with_index do |image_id, index|
        @project.content_positions.create!(
          positionable_type: 'ProjectImage',
          positionable_id: image_id,
          position: index
        )
      end
    end

    redirect_to @project, notice: 'Danh sách ảnh hiển thị đã được cập nhật thành công.'
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
      video_vertical_attributes: %i[id url _destroy],
      descriptions_attributes: %i[id content position_display _destroy]
    )
  end

  def require_admin
    return if admin_logged_in?

    redirect_to login_path, alert: 'Bạn cần đăng nhập để thực hiện hành động này.'
  end
end
