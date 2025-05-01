class ProjectsController < ApplicationController
  before_action :require_admin
  before_action :set_project, only: %i[show edit update destroy reload_images]

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

  private

  def set_project
    @project = Project.find(params[:id])
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
end
