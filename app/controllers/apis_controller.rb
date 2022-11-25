class ApisController < ActionController::API
  before_action :authenticate_request, except: %w[create_or_update_user register_or_update_sales_user]
  around_action :log_standard_errors
  before_action :set_current_user, except: %w[create_or_update_user register_or_update_sales_user]
  before_action :set_current_client, except: %w[create_or_update_user register_or_update_sales_user]

  private

  def authenticate_request
    flag = false
    if request.headers['Api-Key']
      api_key = request.headers['Api-Key']
      @crm = Crm::Base.where(api_key: api_key).first
      if @crm.present?
        flag = true
      else
        message = I18n.t("controller.apis.message.incorrect_key")
      end
    else
      message = I18n.t("controller.apis.message.parameters_missing")
    end
    render json: { errors: [message] }, status: :unauthorized unless flag
  end

  def log_standard_errors
    begin
      yield
    rescue StandardError => e
      create_error_log e
    end
  end

  def set_current_user
    @current_user = @crm.try(:user)
  end

  def set_current_client
    @current_client = @crm.try(:booking_portal_client)
  end

  def create_error_log e
    _error_code = SecureRandom.hex(4)
    Rails.logger.error "[API-V1][ERR] [#{_error_code}] #{e.message} - #{e.backtrace}"
    render json: { errors: [I18n.t("controller.apis.errors.went_wrong", name: "#{_error_code}")] }, status: 500
  end

end
