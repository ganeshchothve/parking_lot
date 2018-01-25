class PaymentController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :verify_authenticity_token
  
  layout :set_layout

  def process_payment
    if Rails.env.development? || request.post?
      eval("handle_#{params[:gateway]}")
    else
      redirect_to :dashboard_receipts_path
    end
  end

  def handle_hdfc
    @receipt = Receipt.where(order_id:params[:orderNo]).first
    encResponse = params[:encResp]
    @receipt.handle_response_for_hdfc(encResponse)

    #handle_success(encResponse) # TODO: handle this based on payment gateway response)
    # handle_failure # TODO: handle this based on payment gateway response)
  end

  private
  def handle_success response
    
    
    unless @receipt.save(validate: false)
      # TODO: send us and embassy team an error message. Escalate this.
    end
  end

  def handle_failure
    @receipt.status = 'failed'
    unless @receipt.save(validate: false)
      # TODO: send us and embassy team an error message. Escalate this.
    end
  end
end
