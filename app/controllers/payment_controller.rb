class PaymentController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_user!
  skip_before_action :verify_authenticity_token

  layout :set_layout

  def process_payment
    @receipt = Receipt.where(receipt_id: params[:receipt_id])
    if Rails.env.development? || request.post?
      @receipt.payment_gateway_service.response_handler!(params)
    else
      redirect_to :dashboard_receipts_path
    end
  end
end
