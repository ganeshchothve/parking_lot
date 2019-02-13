class ApisController < ActionController::API
  private

  def authenticate_request
    flag = false
    if request.headers['Api-key'] && request.headers['HTTP_HOST']
      api_key = request.headers['Api-key']
      domain = request.headers['HTTP_HOST']
      @app = ExternalApi.where(domain: domain).first
      if @app.present?
        if api_key == @app.api_key
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
    render json: { status: 'error', message: message } unless flag
  end
end
