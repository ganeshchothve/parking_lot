class PaymentController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_user!

  layout :set_layout

  def process_payment
    @receipt = Receipt.pending.where(receipt_id: params[:receipt_id]).first
    if @receipt.present? && @receipt.payment_gateway_service.present?
      @receipt.payment_gateway_service.response_handler!(params)
    else
      redirect_to dashboard_path, notice: I18n.t("controller.receipts.notice.no_pending")
    end
  end
end
