class UserRequest::CancellationObserver < Mongoid::Observer
  def after_create(user_request)
    user_request.booking_detail.cancellation_requested!
  end

  def after_update(user_request)
    if user_request.status_changed? && user_request.booking_detail.present?
      if user_request.processing?
        flag = 'true'
        arr = []
        user_request.booking_detail.receipts.each do |r|
          arr << r.id
          case r.status
          when 'success'
            r.available_for_refund! ? true : flag = r.error_messages.full_messages
          when 'clearance_pending'
            # move to state machine receipt
            new_receipt = r.dup
            r.cancel!
            r.save ? true : flag = r.error_messages.full_messages
            new_receipt.project_unit = nil
            new_receipt.save ? true : flag = new_receipt.error_messages.full_messages
            arr << new_receipt.id
          when 'pending'
            r.project_unit = nil
            r.save ? true : flag = r.error_messages.full_messages
          end
        end

        make_project_unit_available = ProjectUnit.booking_stages.include?(user_request.project_unit.status)
        make_project_unit_available &&= user_request.user_id == user_request.project_unit.user_id

        if make_project_unit_available && flag == 'true'
          project_unit = user_request.project_unit
          project_unit.processing_user_request = true
          project_unit.make_available
          project_unit.save(validate: false) ? true : flag = project_unit.error_messages.full_messages
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
        else
          flag = 'Project Unit unavailable'
        end
        if flag == 'true'
          user_request.booking_detail.cancelled!
          user_request.resolved!
          user_request.save
        else
          arr.each do |a|
            r = Receipt.find(a)
            case r.status
            when 'available_for_refund'
              r.success!
            when 'cancelled'
              r.clearance_pending!
            when 'clearance_pending'
              r.destroy
            when 'pending'
              r.project_unit = user_request.project_unit
            end
          end
          user_request.booking_detail.cancellation_rejected
          user_request.rejected
          Note.create(note: flag, notable: user_request.booking_detail)
        end
      elsif user_request.rejected?
        user_request.booking_detail.cancellation_rejected!
        user_request.booking_detail.notes = user_request.notes
        user_request.booking_detail.save
      end
    end
  end
end
