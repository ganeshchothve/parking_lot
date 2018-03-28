class ReceiptMailer < ApplicationMailer
  default from: "Embassy Springs <no-reply@embassysprings.com>"

  def send_failure receipt_id
    @receipt = Receipt.find(receipt_id)
    @user = @receipt.user
    @project_unit = @receipt.project_unit
    @cp = @user.channel_partner
    cc = @cp.present? ? [@cp.email] : []
    cc += default_team
    mail(to: @user.email, cc: cc, subject: "Payment #{@receipt.receipt_id} Failed!")
  end

  def send_success receipt_id
    @receipt = Receipt.find(receipt_id)
    @user = @receipt.user
    @project_unit = @receipt.project_unit
    @cp = @user.channel_partner
    cc = @cp.present? ? [@cp.email] : []
    cc += default_team
    mail(to: @user.email, cc: cc, subject: "Payment #{@receipt.receipt_id} Successful")
    # mail(to: "ashish.c@amuratech.com", cc: cc, subject: "Payment #{@receipt.receipt_id} Successful")
  end

  def send_clearance_pending receipt_id
    @receipt = Receipt.find(receipt_id)
    @user = @receipt.user
    @project_unit = @receipt.project_unit || @receipt.reference_project_unit
    @cp = @user.channel_partner
    cc = @cp.present? ? [@cp.email] : []
    cc += default_team
    mail(to: @user.email, cc: cc, subject: "Payment #{@receipt.receipt_id} has reached the developer and is pending clearance")
  end

  def send_pending_non_online receipt_id
    @receipt = Receipt.find(receipt_id)
    @user = @receipt.user
    @project_unit = @receipt.project_unit || @receipt.reference_project_unit
    @cp = @user.channel_partner
    cc = @cp.present? ? [@cp.email] : []
    cc += default_team
    cc += [@user.email]
    mail(to: crm_team, cc: cc, subject: "Payment #{@receipt.receipt_id} has been collected by channel partner")
  end

  def receipt_email receipt_id
    @receipt = Receipt.find(receipt_id)
    @user = @receipt.user
    @project_unit = @receipt.project_unit
    @cp = @user.channel_partner
    cc = @cp.present? ? [@cp.email] : []
    cc += default_team
    cc += [@user.email]
    attachments["receipt_mail.pdf"] = File.read("#{Rails.root}/tmp/receipt_mail.pdf")
    mail(to: @user.email, subject: "Payment #{@receipt.receipt_id} Structure")
  end

  def send_receipt receipt_id
    @receipt = Receipt.find(receipt_id)
    @user = @receipt.user
    @project_unit = @receipt.project_unit
    @cp = @user.channel_partner
    cc = @cp.present? ? [@cp.email] : []
    cc += default_team
    cc += [@user.email]
    attachments["receipt.pdf"] = File.read("#{Rails.root}/tmp/receipt.pdf")
    mail(to: @user.email, subject: "Payment #{@receipt.receipt_id} Successful Slip")
  end
end
