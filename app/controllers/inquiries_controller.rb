class InquiriesController < ApplicationController
  before_action :require_admin

  def index
    @inquiries = Inquiry.order(created_at: :desc)
    if params[:q].present?
      @inquiries = @inquiries.where(
        'full_name ILIKE :q OR email ILIKE :q OR event_type ILIKE :q OR message ILIKE :q',
        q: "%#{params[:q]}%"
      )
    end
    @inquiries = @inquiries.page(params[:page]).per(15)
  end

  def show
    @inquiry = Inquiry.find(params[:id])
  end

  def destroy
    @inquiry = Inquiry.find(params[:id])
    name = @inquiry.full_name
    @inquiry.destroy
    redirect_to inquiries_path, notice: "Đã xóa liên hệ của \"#{name}\"."
  end

  private

  def require_admin
    return if admin_logged_in?

    redirect_to login_path, alert: 'Bạn cần đăng nhập để xem danh sách liên hệ.'
  end
end
