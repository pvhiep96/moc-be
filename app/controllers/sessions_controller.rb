class SessionsController < ApplicationController
  def new
  end

  def create
    admin = Admin.find_by(user_name: params[:user_name])
    if admin && admin.authenticate(params[:password])
      session[:admin_id] = admin.id
      redirect_to projects_path, notice: 'Logged in successfully'
    else
      flash.now[:alert] = 'Invalid username or password'
      render :new
    end
  end

  def destroy
    session[:admin_id] = nil
    redirect_to projects_path, notice: 'Logged out successfully'
  end
end
