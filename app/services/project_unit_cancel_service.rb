class ProjectUnitCancelService
  attr_reader :user_request

  def initialize(user_request)
    @user_request = user_request
  end

  def resolve
    booking_detail = user_request.try(:booking_detail)
    error_messages = ''
    arr = []
    booking_detail.receipts.each do |receipt|
      arr << receipt.id
      case receipt.status
      when 'success'
        unless receipt.available_for_refund!
          error_messages = receipt.errors.full_messages
          break
        end
      when 'clearance_pending'
        # move to state machine receipt
        new_receipt = receipt.dup
        unless receipt.cancel!
          error_messages = receipt.errors.full_messages
          break
        end
        new_receipt.project_unit = nil
        unless new_receipt.save
          error_messages = new_receipt.errors.full_messages
          break
        end
        arr << new_receipt.id
      when 'pending'
        receipt.project_unit = nil
        unless receipt.save
          error_messages = receipt.errors.full_messages
          break
        end
      end
    end
    make_project_unit_available = ProjectUnit.booking_stages.include?(user_request.project_unit.status)
    make_project_unit_available &&= user_request.user_id == user_request.project_unit.user_id
    if error_messages.blank?
      if make_project_unit_available
        project_unit = user_request.project_unit
        project_unit.processing_user_request = true
        project_unit.make_available
        project_unit.save(validate: false) ? true : error_messages = project_unit.errors.full_messages
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
      else error_messages.blank?
        error_messages = ['Project Unit unavailable']
      end
    end
    if error_messages.blank?
      user_request.resolved!
    else
      arr.each do |a|
        receipt = Receipt.find(a)
        case receipt.status
        when 'available_for_refund'
          receipt.success!
        when 'cancelled'
          receipt.set(status: 'clearance_pending')
        when 'clearance_pending'
          receipt.destroy if receipt.project_unit.blank?
        when 'pending'
          receipt.set(project_unit_id: user_request.project_unit.id)
        end
      end
      user_request.rejected!
      Note.create(note: error_messages, notable: booking_detail)
    end
  end

  def reject
    booking_detail = user_request.try(:booking_detail)
    booking_detail.notes = user_request.notes
    booking_detail.save
  end
end
