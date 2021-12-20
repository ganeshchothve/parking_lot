class ApplicationController < ActionController::Base
  include ApplicationConcern
  include Pundit
  include ApplicationHelper

  before_action :store_user_location!, if: :storable_location?
  before_action :set_locale
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_cache_headers, :set_request_store, :set_cookies
  before_action :load_hold_unit
  before_action :set_current_client
  around_action :apply_project_scope, if: :current_user, unless: proc { current_user.role?('channel_partner') && params[:controller] == 'admin/projects' }

  acts_as_token_authentication_handler_for User, if: :token_authentication_valid_params?

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  helper_method :home_path
  protect_from_forgery with: :exception, prepend: true
  skip_before_action :verify_authenticity_token, if: -> { params[:user_token].present? }
  
  layout :set_layout

  rescue_from ActionController::InvalidAuthenticityToken, with: :invalid_authenticity_token


  def after_sign_in_path_for(resource_or_scope)
    ApplicationLog.user_log(current_user.id, 'sign_in', RequestStore.store[:logging])
    home_path(current_user)
  end

  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end

  def home_path(current_user)
    if current_user
      if (current_user.buyer? || !current_user.role.in?(User::ALL_PROJECT_ACCESS + %w(channel_partner))) && params[:controller] == 'local_devise/sessions'
        buyer_select_project_path
      else
        _path = admin_site_visits_path if current_user.role?('dev_sourcing_manager')
        stored_location_for(current_user) || _path || dashboard_path
      end
    else
      return root_path
    end
  end

  protected

  def set_current_client
    unless current_client
      redirect_to welcome_path, alert: t('controller.application.set_current_client')
    end
  end

  def set_layout
    devise_controller? ? 'devise' : 'application'
  end

  private

  def apply_project_scope
    project_scope = Project.where(Project.user_based_scope(current_user, params))
    Project.with_scope(policy_scope(project_scope)) do
      yield
    end
  end

  def after_successful_token_authentication
  end

  def storable_location?
    request.get? && is_navigational_format? && !devise_controller? && !request.xhr? &&
      (
        !user_signed_in? &&
        params[:controller].in?([
          'buyer/receipts',
          'buyer/booking_details/receipts',
          'admin/users'
        ]) &&
        params[:action].in?(%w(index show new))
      )
  end

  def store_user_location!
    # :user is the scope we are authenticating
    store_location_for(:user, request.fullpath)
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
    #srds = ["5b2a1de1923d4a2f663ea92c", "5b2a1e33923d4a77ecbaf19a", "5b2a1e94923d4a32e23ea89a", "5b2a1ea6923d4a423473df75", "5b2a1eb7923d4a1cb56df504", "5b2a1f41923d4a3ad670e860", "5b2a1f53923d4a2f663ea96e", "5b2a1f64923d4a55ce69747a", "5b2a1f78923d4a2f663ea979", "5b2a1f9a923d4a5d9fe25fa4", "5b2a1fac923d4a2f8b3ea93d", "5b2a1fbb923d4a423473e135", "5b2a1fe6923d4a2f663ea98f", "5b2a1ff5923d4a423473e14a", "5b2a2005923d4a5d9fe25fc7", "5b2a2019923d4a423473e152", "5b2a202b923d4a33713ea888", "5b2a2046923d4a3ad670e883"]
    #tmp = params[:srd]
    #if tmp.present?
    #  if srds.include?(params[:srd])
    #    cookies[:srd] =  tmp
    #    cookies[:portal_cp_id] =  "5b08fa89f294971c8184aa68"
    #  end
    #end

    if current_user.blank? && params[:srd].present?
      cookies[:srd] = params[:srd]
    end

    if params[:portal_cp_id].present?
      cookies[:portal_cp_id] = params[:portal_cp_id]
    end

    if params[:manager_id] && (params[:controller] == 'local_devise/confirmations' && params[:action] == 'show')
      cookies.signed[:manager_id] = {
        value: params[:manager_id],
        expires: (Rails.env.production? ? 1.hour.from_now : 5.minutes.from_now)
      }
    end

  end

  def load_hold_unit
    if current_user
      @current_unit = current_user.project_units.where(status: "hold").first
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name, :phone, :email, :password, :manager_id, :campaign, :source, :sub_source, :medium, :term])
    devise_parameter_sanitizer.permit(:sign_in, keys: [:login, :login_otp, :password, :password_confirmation, :manager_id])
    devise_parameter_sanitizer.permit(:otp, keys: [:login, :login_otp, :password, :password_confirmation, :manager_id])
    devise_parameter_sanitizer.permit(:account_update, keys: [:phone, :email, :password, :password_confirmation, :current_password, :manager_id])
  end

  def token_authentication_valid_params?
    params[:user_email].present? && params[:user_token].present?
  end

  def user_not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore.split("/").join('.')
    policy_name += "."
    policy_name += exception.query.to_s
    if exception.policy.try(:condition)
      policy_name += "."
      policy_name += exception.policy.condition.to_s
    end
    alert = t policy_name, scope: "pundit", default: :default
    respond_to do |format|
      unless request.referer && request.referer.include?('remote-state') && request.method == 'GET'
        format.html { redirect_to (user_signed_in? ? dashboard_path : root_path), alert: alert }
        format.json { render json: { errors: alert }, status: 403 }
      else
        # Handle response for remote-state url requests.
        format.html do
          render plain: '
            <div class="modal fade right fixed-header-footer" role="dialog" id="modal-remote-form-inner">
              <div class="modal-dialog modal-lg" role="document">
                <div class="modal-content">
                  <div class="modal-header">
                    <h3 class="title">' + params[:controller].titleize + '</h3>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                  </div>
                  <div class="modal-body">' + alert + '</div>
                  <div class="modal-footer"></div>
                </div>
              </div>
            </div>'
        end
      end
    end
  end

  def invalid_authenticity_token
    alert = t('controller.application.invalid')
    respond_to do |format|
      format.html { render json: alert }
      format.json { render json: { errors: alert }, status: 403 }
    end
  end

  # For VAPT we want to protect Site with ony permited origins
  def valid_request_origin? # :doc:
    _valid = super

    _valid && ( (current_client.try(:booking_portal_domains) || []).include?( URI.parse( request.origin.to_s ).host ) || Rails.env.development? || Rails.env.test? )
  end

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

  def default_url_options
    { locale: I18n.locale }
  end
end
