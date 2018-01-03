class PaymentController < ApplicationController
  before_action :authenticate_user!
  layout 'dashboard'

  def process_payment
    if Rails.env.development? || request.post?
      # eval("handle_#{params[:gateway]}")
      handle_hdfc
    else
      redirect_to :dashboard_receipts_path
    end
  end

  def handle_hdfc
    @receipt = Receipt.find(params[:receipt_id])
    handle_success(SecureRandom.hex) # TODO: handle this based on payment gateway response)
    # handle_failure # TODO: handle this based on payment gateway response)
    # handle_error
  end

  private
  def handle_success payment_identifier
    @receipt.payment_identifier = payment_identifier
    @receipt.status = 'success'
    # block the unit
    project_unit = @receipt.project_unit
    authorize project_unit
    if @receipt.save(validate: false)
      if @receipt.payment_type == 'blocking' && project_unit.status == 'hold'
        project_unit.status = 'blocked'
      elsif @receipt.payment_type == 'booking' && (project_unit.status == 'booked_tentative' || project_unit.status == 'blocked')
        if project_unit.total_balance_pending == 0
          project_unit.status = 'booked_confirmed'
        else
          project_unit.status = 'booked_tentative'
        end
      end
      if project_unit.save(validate: false)
      else
        # TODO: send us and embassy team an error message. Escalate this.
      end
    else
      # TODO: send us and embassy team an error message. Escalate this.
    end
  end

  def handle_failure
    @receipt.status = 'failed'
    project_unit = @receipt.project_unit
    authorize project_unit
    if @receipt.payment_type == 'blocking' && project_unit.status == 'hold'
      project_unit.status = 'available'
      project_unit.user_id = nil
    end
    if @receipt.save(validate: false) && project_unit.save(validate: false)
    else
    # TODO: send us and embassy team an error message. Escalate this.
    end
  end
end
