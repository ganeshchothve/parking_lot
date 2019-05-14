module ReceiptNotificationSender
  def self.send id, old_status, new_status
  end

  def send_success_notification
    if self.user.booking_portal_client.email_enabled?
      Email.create!({
        booking_portal_client_id: user.booking_portal_client_id,
        email_template_id:Template::EmailTemplate.find_by(name: "receipt_success").id,
        recipients: [user],
        cc_recipients: (user.manager_id.present? ? [user.manager] : []),
        triggered_by_id: receipt.id,
        triggered_by_type: receipt.class.to_s
      })
    end
  end

  def send_failure_notification
    if self.user.booking_portal_client.email_enabled?
      Email.create!({
        booking_portal_client_id: project_unit.booking_portal_client_id,
        email_template_id:Template::EmailTemplate.find_by(name: "receipt_failed").id,
        recipients: [user],
        cc_recipients: (user.manager_id.present? ? [user.manager] : []),
        triggered_by_id: receipt.id,
        triggered_by_type: receipt.class.to_s
      })
    end
  end

  def send_clearance_pending_notification
    if self.user.booking_portal_client.email_enabled?
      Email.create!({
        booking_portal_client_id: project_unit.booking_portal_client_id,
        email_template_id:Template::EmailTemplate.find_by(name: "receipt_clearance_pending").id,
        recipients: [user],
        cc_recipients: (user.manager_id.present? ? [user.manager] : []),
        triggered_by_id: receipt.id,
        triggered_by_type: receipt.class.to_s
      })
    end
  end

  def send_sms_notification
    if self.user.booking_portal_client.sms_enabled?
      Sms.create!(
        booking_portal_client_id: user.booking_portal_client_id,
        recipient_id: self.user_id,
        sms_template_id: Template::SmsTemplate.find_by(name: "receipt_#{self.status}").id,
        triggered_by_id: self.id,
        triggered_by_type: self.class.to_s
      )
    end
  end

  def send_pending_notification
    # Send email to crm team if cheque non-online & pending
    if self.status == 'pending' && self.payment_mode != 'online'
      if user.booking_portal_client.email_enabled?
        Email.create!({
          booking_portal_client_id: user.booking_portal_client_id,
          email_template_id:Template::EmailTemplate.find_by(name: "receipt_pending").id,
          recipients: [user],
          cc_recipients: (user.manager_id.present? ? [user.manager] : []),
          triggered_by_id: receipt.id,
          triggered_by_type: receipt.class.to_s
        })
      end
      if self.user.booking_portal_client.sms_enabled?
        Sms.create!(
          booking_portal_client_id: user.booking_portal_client_id,
          recipient_id: self.user_id,
          sms_template_id: Template::SmsTemplate.find_by(name: "receipt_pending").id,
          triggered_by_id: self.id,
          triggered_by_type: self.class.to_s
        )
      end
    end
  end
end
