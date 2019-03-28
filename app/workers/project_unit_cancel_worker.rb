class ProjectUnitCancelWorker
  include Sidekiq::Worker
  attr_reader :user_request, :booking_detail

  def perform(user_request_id)
    @user_request = UserRequest.find(user_request_id)
    @booking_detail = user_request.try(:booking_detail)
    resolve
  end

  def update_receipts(old_receipts_arr, new_receipts_arr, error_messages)
    booking_detail.receipts.each do |receipt|
      next unless %w[pending clearance_pending success].include?(receipt.status)
      old_receipts_arr << [receipt.id, receipt.status]
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
        new_receipts_arr << new_receipt
      when 'pending'
        receipt.cancel!
        unless receipt.save
          error_messages = receipt.errors.full_messages
          break
        end
      end
    end
    error_messages
  end

  def can_update_project_unit_to_available?
    make_project_unit_available = ProjectUnit.booking_stages.include?(booking_detail.project_unit.status) && (user_request.user_id == booking_detail.project_unit.user_id)
  end

  def send_email
    Email.create!(
      booking_portal_client_id: user_request.user.booking_portal_client_id,
      email_template_id: Template::EmailTemplate.find_by(name: "#{user_request.class.model_name.element}_request_#{user_request.status}").id,
      recipients: [user_request.user],
      cc_recipients: (user_request.user.manager_id.present? ? [user_request.user.manager] : []),
      triggered_by_id: user_request.id,
      triggered_by_type: user_request.class.to_s
    )
  end

  def send_sms
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

  def update_project_unit_to_available(error_messages)
    project_unit = booking_detail.project_unit
    project_unit.processing_user_request = true
    project_unit.make_available
    if project_unit.save
      send_email if user_request.user.booking_portal_client.email_enabled?
      send_sms
    else
      error_messages = project_unit.errors.full_messages
    end
    error_messages
  end

  def revert_updated_receipts(old_receipts_arr, new_receipts_arr)
    old_receipts_arr.each do |a|
      receipt = Receipt.find(a[0])
      receipt.set(status: a[1])
    end
    new_receipts_arr.each(&:destroy)
  end

  def resolve
    old_receipts_arr = []
    new_receipts_arr = []
    error_messages = ''
    error_messages = update_receipts(old_receipts_arr, new_receipts_arr, error_messages)
    if error_messages.blank?
      can_update_project_unit_to_available? ? error_messages = update_project_unit_to_available(error_messages) : error_messages = ['Project Unit unavailable']
    end
    if error_messages.blank?
      booking_detail.cancel!
    else
      revert_updated_receipts(old_receipts_arr, new_receipts_arr)
      user_request.set(reason_for_failure: error_messages)
      booking_detail.cancellation_rejected!
    end
  end
end
