class ReceiptMailer < ApplicationMailer
  def send_failure receipt_id
    @receipt = Receipt.find(receipt_id)
    @user = @receipt.user
    @project_unit = @receipt.project_unit || @receipt.reference_project_unit
    @cp = @user.channel_partner
    cc = @cp.present? ? [@cp.email] : []
    mail(to: @user.email, cc: cc, subject: "Payment #{@receipt.receipt_id} Failed!")
  end

  def send_success receipt_id
    @receipt = Receipt.find(receipt_id)
    @user = @receipt.user
    @project_unit = @receipt.project_unit || @receipt.reference_project_unit
    @cp = @user.channel_partner
    cc = @cp.present? ? [@cp.email] : []
    attachments["Receipt.pdf"] = WickedPdf.new.pdf_from_string(
      render_to_string(pdf: "receipt", template: "receipts/show.pdf.erb"))
    mail(to: @user.email, cc: cc, subject: "Payment #{@receipt.receipt_id} Successful")
  end

  def send_clearance_pending receipt_id
    @receipt = Receipt.find(receipt_id)
    @user = @receipt.user
    @project_unit = @receipt.project_unit || @receipt.reference_project_unit
    @cp = @user.channel_partner
    cc = @cp.present? ? [@cp.email] : []
    mail(to: @user.email, cc: cc, subject: "Payment #{@receipt.receipt_id} is pending clearance")
  end

  def send_pending_non_online receipt_id
    @receipt = Receipt.find(receipt_id)
    @user = @receipt.user
    @project_unit = @receipt.project_unit || @receipt.reference_project_unit
    @cp = @user.channel_partner
    cc = @cp.present? ? [@cp.email] : []
    cc += [@user.email]
    mail(to: crm_team, cc: cc, subject: "Payment #{@receipt.receipt_id} has been collected for your " + @project_unit.project_name)
  end

  def receipt_email receipt_id
    @receipt = Receipt.find(receipt_id)
    @user = @receipt.user
    @project_unit = @receipt.project_unit || @receipt.reference_project_unit
    @cp = @user.channel_partner
    cc = @cp.present? ? [@cp.email] : []
    cc += [@user.email]
    attachments["receipt_mail.pdf"] = File.read("#{Rails.root}/tmp/receipt_mail.pdf")
    mail(to: @user.email, subject: "Payment #{@receipt.receipt_id} Structure")
  end

  def send_receipt receipt_id
    @receipt = Receipt.find(receipt_id)
    @user = @receipt.user
    @project_unit = @receipt.project_unit || @receipt.reference_project_unit
    @cp = @user.channel_partner
    cc = @cp.present? ? [@cp.email] : []
    cc += [@user.email]
    attachments["receipt.pdf"] = File.read("#{Rails.root}/tmp/receipt.pdf")
    mail(to: @user.email, subject: "Payment #{@receipt.receipt_id} Successful Slip")
  end

  def days_to_go(receipt_id, days)
    @receipt = Receipt.find(receipt_id)
    @user = @receipt.user
    @project_unit = @receipt.project_unit
    @cp = @user.channel_partner
    cc = @cp.present? ? [@cp.email] : []
    @day = days.to_i
    mail(to: @user.email, cc: cc, subject: "#{@day} days to go!")
  end
end
