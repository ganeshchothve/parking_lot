class ApisController < ActionController::API
  before_action :authenticate_request
  around_action :log_standard_errors
  before_action :set_current_user
  before_action :set_current_client

  private

  def authenticate_request
    flag = false
    if request.headers['Api-Key']
      api_key = request.headers['Api-Key']
      response = JSON.parse(Base64.decode64(api_key)) rescue {}
      @crm = Crm::Base.where(api_key: api_key).first || Crm::Base.where(api_key: response['value']).first
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
    @current_client = @crm.booking_portal_client
  end

  def create_error_log e
    _error_code = SecureRandom.hex(4)
    Rails.logger.error "[API-V1][ERR] [#{_error_code}] #{e.message} - #{e.backtrace}"
    render json: { errors: [I18n.t("controller.apis.errors.went_wrong", name: "#{_error_code}")] }, status: 500
  end

end
