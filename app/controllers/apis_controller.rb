class ApisController < ActionController::API
  before_action :authenticate_request

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
    render json: { message: message }, status: :unauthorized unless flag
  end
end
