class PaymentController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_user!

  layout :set_layout

  def process_payment
    @receipt = Receipt.where(receipt_id: params[:receipt_id]).first
    @receipt.payment_gateway_service.response_handler!(params)
  end
end
