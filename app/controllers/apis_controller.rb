class ApisController < ActionController::API
  include ActionController::MimeResponds
  before_action :authenticate_request
  around_action :log_standard_errors
  before_action :set_current_user
  before_action :set_current_client

  def pundit_user
    @current_user
  end

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
      log_responses_to_api_log(request)
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
    @errors = e.message
    log_responses_to_api_log(request)
    render json: { errors: [I18n.t("controller.apis.errors.went_wrong", name: "#{_error_code}")] }, status: 500
  end

  def log_responses_to_api_log(request)
    request_url = request.url
    request = [params.as_json.to_h] rescue []
    response = [@errors || @message]
    resource = (@resource || @current_user || @current_client)
    response_type = "Array"
    booking_portal_client = @current_client
    status = @errors.present? ? "Error" : "Success"
    message = @errors || @message
    log_type = "Webhook"
    ApiLog.log_responses(request_url, request, response, resource, response_type, booking_portal_client, status, message, log_type)
  end

end
