class ApplicationController < ActionController::Base

  before_action :set_current_user

  def set_current_user
    if session[:user_id]
      Current.user = User.find_by(id: session[:user_id])
    end
  end

  def require_user_logged_in!
    redirect_to root_path, alert: "You must be signed in to do that !" if Current.user.nil?
  end

  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end

  def logged_in?
    !current_user.nil?
  end

  def authenticate_user!
    redirect_to root_path unless logged_in?
  end

end
