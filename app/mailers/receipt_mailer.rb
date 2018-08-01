class ReceiptMailer < ApplicationMailer
  def send_failure receipt_id
    @receipt = Receipt.find(receipt_id)
    @user = @receipt.user
    @cp = @user.channel_partner
    cc = @cp.present? ? [@cp.email] : []
    make_bootstrap_mail(to: @user.email, cc: cc, subject: "Payment #{@receipt.receipt_id} Failed!")
  end

  def send_success receipt_id
    @receipt = Receipt.find(receipt_id)
    @user = @receipt.user
    @cp = @user.channel_partner
    cc = @cp.present? ? [@cp.email] : []
    attachments["Receipt.pdf"] = WickedPdf.new.pdf_from_string(
    render_to_string(pdf: "receipt", template: "receipts/show.pdf.erb"))
    make_bootstrap_mail(to: @user.email, cc: cc, subject: "Payment #{@receipt.receipt_id} Successful")
  end

  def send_clearance_pending receipt_id
    @receipt = Receipt.find(receipt_id)
    @user = @receipt.user
    @cp = @user.channel_partner
    cc = @cp.present? ? [@cp.email] : []
    make_bootstrap_mail(to: @user.email, cc: cc, subject: "Payment #{@receipt.receipt_id} is pending clearance")
  end

  def send_pending_non_online receipt_id
    @receipt = Receipt.find(receipt_id)
    @user = @receipt.user
    @cp = @user.channel_partner
    cc = @cp.present? ? [@cp.email] : []
    cc += [@user.email]
    subject = "Payment Receipt #{@receipt.receipt_id} Collected"
    @preview = "Thank you for your payment of #{number_to_indian_currency(@receipt.total_amount)}"
    make_bootstrap_mail(to: cc, subject: subject)
  end
end
