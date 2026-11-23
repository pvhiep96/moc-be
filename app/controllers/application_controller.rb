class ApplicationController < ActionController::Base
  helper_method :current_admin, :admin_logged_in?

  private

  def current_admin
    @current_admin ||= Admin.find_by(id: session[:admin_id]) if session[:admin_id]
  end

  def admin_logged_in?
    !!current_admin
  end

  def require_admin
    return if admin_logged_in?

    flash[:alert] = 'Bạn cần đăng nhập để truy cập trang này.'
    redirect_to login_path
  end
end
