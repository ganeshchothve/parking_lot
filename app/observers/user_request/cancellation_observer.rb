class UserRequest::CancellationObserver < Mongoid::Observer
  def after_create(user_request)
    user_request.project_unit.booking_detail.cancellation_requested!
  end

  def after_update(user_request)
    if user_request.status_changed? && user_request.project_unit.present?
      if user_request.status == 'resolved'
        user_request.project_unit.booking_detail.receipts.each do |r|
          case r.status
          when 'success'
            r.available_for_refund!
          when 'clearance_pending'
            # move to state machine receipt
            new_receipt = r.dup
            r.status = 'cancelled'
            r.save
            new_receipt.project_unit = nil
            new_receipt.save
          when 'pending'
            r.project_unit = nil
            r.save
          end
        end
        user_request.project_unit.booking_detail.cancelled!
        make_project_unit_available = ProjectUnit.booking_stages.include?(user_request.project_unit.status)
        make_project_unit_available &&= user_request.user_id == user_request.project_unit.user_id

        if make_project_unit_available
          project_unit = user_request.project_unit
          project_unit.processing_user_request = true
          project_unit.make_available
          project_unit.save(validate: false)
          if user_request.user.booking_portal_client.email_enabled?
            Email.create!(
              booking_portal_client_id: user_request.user.booking_portal_client_id,
              email_template_id: Template::EmailTemplate.find_by(name: "#{user_request.class.model_name.element}_request_#{user_request.status}").id,
              recipients: [user_request.user],
              cc_recipients: (user_request.user.manager_id.present? ? [user_request.user.manager] : []),
              triggered_by_id: user_request.id,
              triggered_by_type: user_request.class.to_s
            )
          end

          template = Template::SmsTemplate.where(name: "#{user_request.class.model_name.element}_request_resolved").first
          if template.present? && user_request.user.booking_portal_client.sms_enabled?
            Sms.create!(
              booking_portal_client_id: user_request.user.booking_portal_client_id,
              recipient_id: user_request.user_id,
              sms_template_id: template.id,
              triggered_by_id: user_request.id,
              triggered_by_type: user_request.class.to_s
            )
          end
        end
      elsif user_request.status == 'rejected'
        user_request.project_unit.booking_detail.cancellation_rejected!
        user_request.project_unit.booking_detail.notes = user_request.notes
        user_request.project_unit.booking_detail.save
      end
    end
  end
end
