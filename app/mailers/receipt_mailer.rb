class ReceiptMailer < ApplicationMailer
  default from: 'from@example.com'
  layout 'mailer'

  def send_failure receipt_id
    @receipt = Receipt.find(receipt_id)
    @user = receipt.user
    @project_unit = receipt.project_unit
  end

  def send_success receipt_id
    @receipt = Receipt.find(receipt_id)
    @user = receipt.user
    @project_unit = receipt.project_unit
  end

  def send_clearance_pending receipt_id
    @receipt = Receipt.find(receipt_id)
    @user = receipt.user
    @project_unit = receipt.project_unit
  end
end
