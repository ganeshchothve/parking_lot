class ReceiptObserver < Mongoid::Observer
  def after_save receipt
    user = receipt.user
    project_unit = receipt.project_unit

    # update project unit if a successful receipt is getting attached to a project_unit
    # update the user balance if receipt has no project unit
    if receipt.project_unit_id_changed? && receipt.project_unit_id_was.blank? && ['success', 'clearance_pending'].include?(receipt.status) && !receipt.status_changed?
      project_unit.process_payment!(receipt)
      unless user.save
        # TODO: notify us about this
      end
    end

    # update project unit if receipt status has changed
    if receipt.status_changed?
      project_unit = receipt.project_unit
      if project_unit.present?
        if project_unit.process_payment!(receipt)
        elsif receipt.status != 'clearance_pending'
          # TODO: send us and client team an error message. Escalate this.
        end
      end

      # update user stats if receipt status is success
      if receipt.status == 'success'
        user = receipt.user
        unless user.save
          # TODO: notify us about this
        end
      end
    end


    # Send email to customer
    if receipt.status_changed?
      if receipt.status == 'success'
        # TODO : Sell.Do Receipt
        mailer = ReceiptMailer.send_success(receipt.id.to_s)
        if Rails.env.development?
          mailer.deliver
        else
          mailer.deliver_later
        end
      elsif receipt.status == 'failed'
        # TODO : Sell.Do Receipt
        mailer = ReceiptMailer.send_failure(receipt.id.to_s)
        if Rails.env.development?
          mailer.deliver
        else
          mailer.deliver_later
        end
      elsif receipt.status == 'clearance_pending'
        mailer = ReceiptMailer.send_clearance_pending(receipt.id.to_s)
        if Rails.env.development?
          mailer.deliver
        else
          mailer.deliver_later
        end
      end
      unless receipt.status == "pending"
        Sms.create!(
          booking_portal_client_id: user.booking_portal_client_id,
          recipient_id: receipt.user_id,
          sms_template_id: SmsTemplate.find_by(name: "receipt_#{receipt.status}").id,
          triggered_by_id: receipt.id,
          triggered_by_type: receipt.class.to_s
        )
      end
    end

    # Send email to crm team if cheque non-online & pending
    if receipt.status == 'pending' && receipt.payment_mode != 'online'
      mailer = ReceiptMailer.send_pending_non_online(receipt.id.to_s)
      if Rails.env.development?
        mailer.deliver
      else
        mailer.deliver_later
      end
      Sms.create!(
        booking_portal_client_id: user.booking_portal_client_id,
        recipient_id: receipt.user_id,
        sms_template_id: SmsTemplate.find_by(name: "receipt_pending").id,
        triggered_by_id: receipt.id,
          triggered_by_type: receipt.class.to_s
      )
    end
  end

  def before_save receipt
    if receipt.status_changed? && receipt.status == 'success' && receipt.processed_on.blank?
      receipt.processed_on = Date.today
      receipt.assign!(:order_id) if receipt.order_id.blank?
    end
    receipt.receipt_id = receipt.generate_receipt_id
  end
end
