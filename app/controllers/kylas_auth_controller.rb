# frozen_string_literal: true

# Oauth
class KylasAuthController < ApplicationController
  before_action :kylas_auth_request?
  before_action :authenticate_user!

  def authenticate
    authorization_code = params[:code]

    if authorization_code.present?
      response = Kylas::ExchangeCode.new(authorization_code).call
      if response[:success]
        if current_user.update_users_and_tenants_details(response)
          session.delete(:previous_url) if auth_request?(session[:previous_url])
          flash[:success] = I18n.t('kylas_auth.successfully_installed')
        else
          sign_out current_user
          redirect_to action: :authenticate, code: params[:code] and return
        end
      else
        flash[:alert] = I18n.t('kylas_auth.facing_problem')
      end
    else
      flash[:alert] = I18n.t('kylas_auth.something_went_wrong')
    end
    _path = reset_password_after_first_login_admin_user_path(current_user) if current_user && policy([:admin, current_user]).reset_password_after_first_login?
    redirect_to _path || root_path
  end

  private

  def kylas_auth_request?
    session[:previous_url] = request.fullpath if auth_request?(request.fullpath)
  end
end
