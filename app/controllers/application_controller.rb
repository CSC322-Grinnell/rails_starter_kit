class ApplicationController < ActionController::Base
  def authenticate_admin_user!
    unless current_user && current_user.admin?
      reset_session
      redirect_to new_user_session_path, alert: t('access_denied')
    end
  end

  def after_sign_in_path_for(resource)
    if current_user.admin?
      admin_dashboard_path
    else
      stored_location_for(resource) || super
   end
  end
end
