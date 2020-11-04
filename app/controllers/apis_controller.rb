class ApisController < ActionController::API
  before_action :authenticate_request
  around_action :log_standard_errors

  private

  def authenticate_request
    flag = false
    if request.headers['Client-id'] && request.headers['Client-key']
      api_key = request.headers['Client-key']
      crm_id = request.headers['Client-id']
      @crm = Crm::Base.where(id: crm_id).first
      if @crm.present?
        if api_key == @crm.api_key
          flag = true
        else
          message = 'Incorrect key.'
        end
      else
        message = 'Kindly register with our application.'
      end
    else
      message = 'Required parameters missing.'
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

  def create_error_log e
    _error_code = SecureRandom.hex(4)
    Rails.logger.error "[API-V1][ERR] [#{_error_code}] #{e.message} - #{e.backtrace}"
    render json: { errors: ["Something went wrong. Please contact support team & share the error code: #{_error_code}"] }, status: 500
  end

end
