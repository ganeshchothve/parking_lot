class ApplicationController < ActionController::Base
  acts_as_token_authentication_handler_for User, unless: lambda { |controller| controller.is_a?(HomeController) || controller.is_a?(Api::SellDoController) || (controller.is_a?(ChannelPartnersController)) }
  include Pundit
  helper_method :after_sign_in_path_for
  protect_from_forgery with: :exception
  layout :set_layout
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  
  def after_sign_in_path_for(current_user)
    if current_user.role?('user') || current_user.role?('crm') || current_user.role?('channel_partner')
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
    elsif is_a?(Devise::ConfirmationsController)      
      "dashboard"
    elsif is_a?(ChannelPartnersController)      
      "dashboard"
    else
      "application"
    end
  end

  private
  def after_successful_token_authentication
  end

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    respond_to do |format|
      format.html { redirect_to user_signed_in? ? after_sign_in_path_for(current_user) : root_path }
      format.json { render json: {error: "You are not authorized to access this page"}, status: 403 }
    end
  end
end
