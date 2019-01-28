class ApisController < ActionController::API
  private

  def authenticate_request
    flag = false
    if request.headers['Api-key'] && request.domain
      api_key = request.headers['Api-key']
      domain = request.domain
      @app = External_Api.where(domain: domain).first
      if @app.present?
        encrypted_key = ActiveSupport::MessageEncryptor.new(@app.private_key).encrypt_and_sign(api_key.to_s)
        if encrypted_key == @app.encrypted_api_key
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
    # redirect_to dashboard_path, alert: t(message) if !flag
    render json: { error: message } unless flag # TODO: TEST
    # respond_with(render json: , location: root) if !flag
    flag
  end
end
