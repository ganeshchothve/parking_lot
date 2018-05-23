class PaymentController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_user!

  layout :set_layout

  def process_payment
    @receipt = Receipt.where(receipt_id: params[:receipt_id]).first
    if @receipt.status == "pending" && @receipt.payment_gateway_service.present?
      @receipt.payment_gateway_service.response_handler!(params)
    else
      flash[:notice] = 'You are not allowed to access this page'
      redirect_to home_path(current_user)
    end
  end
end
