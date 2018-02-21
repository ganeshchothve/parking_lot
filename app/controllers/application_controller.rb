class ApplicationController < ActionController::Base
  acts_as_token_authentication_handler_for User
  include Pundit
  helper_method :after_sign_in_path_for
  protect_from_forgery with: :exception

  def after_sign_in_path_for(current_user)
    if current_user.role?('user') || current_user.role?('crm')
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

  private
  def after_successful_token_authentication
  end
end
