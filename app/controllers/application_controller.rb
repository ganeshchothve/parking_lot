class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_cache_headers, :set_request_store, :set_cookies
  before_action :load_and_store_client, :load_project, :load_hold_unit
  acts_as_token_authentication_handler_for User, unless: lambda { |controller| controller.is_a?(HomeController) || controller.is_a?(Api::SellDoController) || (controller.is_a?(ChannelPartnersController)) }
  include Pundit
  helper_method :home_path
  protect_from_forgery with: :exception, prepend: true
  layout :set_layout
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def after_sign_in_path_for(current_user)
    ApplicationLog.user_log(current_user.id, 'sign_in', RequestStore.store[:logging])
    dashboard_path
  end

  def home_path(current_user)
    if current_user
      return dashboard_path
    else
      return root_path
    end
  end

  protected
  def set_layout
    if user_signed_in?
      if current_user.buyer?
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

  def set_request_store
    if user_signed_in?
      hash = {
        user_id: current_user.id,
        user_email: current_user.email,
        role: current_user.role,
        url: request.url,
        ip: request.remote_ip,
        user_agent: request.user_agent,
        method: request.method,
        request_id: request.request_id,
        timestamp: Time.now
      }
      RequestStore.store[:logging] = hash
    end
  end

  def set_cache_headers
    if user_signed_in?
      response.headers["Cache-Control"] = "no-cache, no-store"
      response.headers["Pragma"] = "no-cache"
      response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
    end
  end

  def set_cookies
    srds = ["5b2a1de1923d4a2f663ea92c", "5b2a1e33923d4a77ecbaf19a", "5b2a1e94923d4a32e23ea89a", "5b2a1ea6923d4a423473df75", "5b2a1eb7923d4a1cb56df504", "5b2a1f41923d4a3ad670e860", "5b2a1f53923d4a2f663ea96e", "5b2a1f64923d4a55ce69747a", "5b2a1f78923d4a2f663ea979", "5b2a1f9a923d4a5d9fe25fa4", "5b2a1fac923d4a2f8b3ea93d", "5b2a1fbb923d4a423473e135", "5b2a1fe6923d4a2f663ea98f", "5b2a1ff5923d4a423473e14a", "5b2a2005923d4a5d9fe25fc7", "5b2a2019923d4a423473e152", "5b2a202b923d4a33713ea888", "5b2a2046923d4a3ad670e883"]
    tmp = params[:srd]
    if tmp.present?
      if srds.include?(params[:srd])
        cookies[:srd] =  tmp
        cookies[:portal_cp_id] =  "5b08fa89f294971c8184aa68"
      end
    end

    if params[:portal_cp_id].present?
      cookies[:portal_cp_id] = params[:portal_cp_id]
    end

  end

  def load_and_store_client
    domain = (request.subdomain.present? ? "#{request.subdomain}." : "") + "#{request.domain}"
    @client = Client.in(booking_portal_domains: domain).first
    RequestStore::Base.set "client_id", @client.id
  end

  def load_project
    # TODO: for now we are considering one project per client only so loading first client project here
    @project = @client.projects.first if @client.present?
  end

  def load_hold_unit
    if current_user
      @current_unit = current_user.project_units.where(status: "hold").first
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:phone, :email, :password, :password_confirmation])
    devise_parameter_sanitizer.permit(:sign_in, keys: [:login, :password, :password_confirmation])
    devise_parameter_sanitizer.permit(:otp, keys: [:login, :password, :password_confirmation])
    devise_parameter_sanitizer.permit(:account_update, keys: [:phone, :email, :password, :password_confirmation, :current_password])
  end
end
