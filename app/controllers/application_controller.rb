class ApplicationController < ActionController::Base
  include Pundit
  protect_from_forgery with: :exception

  def after_sign_in_path_for(current_user)
    if current_user.role?('user')
      dashboard_path
    else
      admin_users_path
    end
  end

  protected
  def set_layout
    if user_signed_in?
      if current_user.role?('user')
        'dashboard'
      else
        'admin'
      end
    else
      'application'
    end
  end
end
