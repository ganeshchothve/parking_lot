class ReceiptMailer < ApplicationMailer
  default from: 'from@example.com'
  layout 'mailer'

  def send_failure receipt_id
    @receipt = Receipt.find(receipt_id)
    @user = @receipt.user
    @project_unit = @receipt.project_unit
    mail(to: @user.email, subject: "Payment #{@receipt.receipt_id} Failed")
  end

  def send_success receipt_id
    @receipt = Receipt.find(receipt_id)
    @user = @receipt.user
    @project_unit = @receipt.project_unit
    mail(to: @user.email, subject: "Payment #{@receipt.receipt_id} Successful")
  end

  def send_clearance_pending receipt_id
    @receipt = Receipt.find(receipt_id)
    @user = @receipt.user
    @project_unit = @receipt.project_unit
    mail(to: @user.email, subject: "Payment #{@receipt.receipt_id} has reached the developer and is pending clearance")
  end
end
