class ApplicationController < ActionController::Base
  def authenticate_admin_user!
    unless current_user && current_user.admin?
      reset_session
      redirect_to(new_user_session_path)
    end
  end
end
