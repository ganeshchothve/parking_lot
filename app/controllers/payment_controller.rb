class PaymentController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_user!

  layout :set_layout

  def process_payment
    @receipt = Receipt.pending.where(receipt_id: params[:receipt_id]).first
    if @receipt.present? && @receipt.payment_gateway_service.present?
      @receipt.payment_gateway_service.response_handler!(params)
    else
      redirect_to dashboard_path, notice: 'No pending receipt found.'
    end
  end
end
