class SessionsController < ApplicationController
  def new
  end

  def create
    admin = Admin.find_by(user_name: params[:user_name])
    if admin && admin.authenticate(params[:password])
      session[:admin_id] = admin.id
      redirect_to projects_path, notice: "Xin chào #{admin.fullname.presence || admin.user_name}!"
    else
      flash.now[:alert] = 'Tên đăng nhập hoặc mật khẩu không đúng.'
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session[:admin_id] = nil
    redirect_to login_path, notice: 'Đã đăng xuất.'
  end
end
