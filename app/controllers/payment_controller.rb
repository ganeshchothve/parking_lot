class PaymentController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_user!

  layout :set_layout

  def process_payment
    @receipt = Receipt.pending.where(booking_portal_client_id: current_client.try(:id)).where(receipt_id: params[:receipt_id]).first
    if @receipt.present? && @receipt.payment_gateway_service.present?
      @receipt.payment_gateway_service.response_handler!(params)
      redirect_to action: 'process_payment', receipt_id: @receipt.id
    else
      @receipt = Receipt.where(booking_portal_client_id: current_client.try(:id)).where(_id: params[:receipt_id]).first
      unless @receipt.present?
        if current_user.buyer?
          flash[:alert] = I18n.t('app.errors.payment_error')
          sign_out current_user and redirect_to root_path
        else
          redirect_to home_path(current_user), alert: I18n.t('app.errors.payment_error')
        end
      end
    end
  end
end
