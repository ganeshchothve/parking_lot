class ApplicationController < ActionController::Base
  acts_as_token_authentication_handler_for User, unless: lambda { |controller| controller.is_a?(HomeController) }
  include Pundit
  helper_method :after_sign_in_path_for
  protect_from_forgery with: :exception
  layout :set_layout
  
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
    elsif is_a?(Devise::SessionsController)
      "dashboard"
    elsif is_a?(Devise::PasswordsController)
      "dashboard"
    elsif is_a?(Devise::UnlocksController)
      "dashboard"
    elsif is_a?(Devise::RegistrationsController)
      "dashboard"
    elsif is_a?(Devise::RegistrationsController)      
      "dashboard"
    else
      "application"
    end
  end

  private
  def after_successful_token_authentication
  end
end
