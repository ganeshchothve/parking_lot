class PaymentController < ApplicationController
  before_action :authenticate_user!

  layout :set_layout

  def process_payment
    if Rails.env.development? || request.post?
      eval("handle_#{params[:gateway]}")
    else
      redirect_to :dashboard_receipts_path
    end
  end

  def handle_hdfc
    @receipt = Receipt.find(params[:receipt_id])
    handle_success(SecureRandom.hex) # TODO: handle this based on payment gateway response)
    # handle_failure # TODO: handle this based on payment gateway response)
  end

  private
  def handle_success payment_identifier
    @receipt.payment_identifier = payment_identifier
    @receipt.status = 'success'
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
