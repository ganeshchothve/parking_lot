class ReceiptMailer < ApplicationMailer

  def send_failure receipt_id
    @receipt = Receipt.find(receipt_id)
    @user = @receipt.user
    @project_unit = @receipt.project_unit
    @cp = @user.channel_partner
    cc = @cp.present? ? [@cp.email] : []
    cc += default_team
    mail(to: @user.email, cc: cc, subject: "Payment #{@receipt.receipt_id} Failed")
  end

  def send_success receipt_id
    @receipt = Receipt.find(receipt_id)
    @user = @receipt.user
    @project_unit = @receipt.project_unit
    @cp = @user.channel_partner
    cc = @cp.present? ? [@cp.email] : []
    cc += default_team
    # mail(to: @user.email, cc: cc, subject: "Payment #{@receipt.receipt_id} Successful")

    mail(to: "ashish.c@amuratech.com", cc: cc, subject: "Payment #{@receipt.receipt_id} Successful")
  end

  def send_clearance_pending receipt_id
    @receipt = Receipt.find(receipt_id)
    @user = @receipt.user
    @project_unit = @receipt.project_unit
    @cp = @user.channel_partner
    cc = @cp.present? ? [@cp.email] : []
    cc += default_team
    mail(to: @user.email, cc: cc, subject: "Payment #{@receipt.receipt_id} has reached the developer and is pending clearance")
  end

  def send_pending_non_online receipt_id
    @receipt = Receipt.find(receipt_id)
    @user = @receipt.user
    @project_unit = @receipt.project_unit
    @cp = @user.channel_partner
    cc = @cp.present? ? [@cp.email] : []
    cc += default_team
    cc += [@user.email]
    mail(to: crm_team, cc: cc, subject: "Payment #{@receipt.receipt_id} has been collected by channel partner")
  end

  def send_receipt receipt_id
    @receipt = Receipt.find(receipt_id)
    @user = @receipt.user
    @project_unit = @receipt.project_unit
    @cp = @user.channel_partner
    cc = @cp.present? ? [@cp.email] : []
    cc += default_team
    cc += [@user.email]
    mail.attachments["receipt.pdf"] = File.read("#{Rails.root}/tmp/pdf/receipt.pdf")
    mail(to: "ashish.c@amuratech.com", subject: "Payment #{@receipt.receipt_id} Successful")
  end
end
