class ProjectUnitSwapService
  attr_accessor :user_request, :current_booking_detail, :alternate_project_unit

  # def initialize project_unit_id, alternate_project_unit_id
  #   @project_unit = ProjectUnit.find project_unit_id
  #   @alternate_project_unit = ProjectUnit.find alternate_project_unit_id
  # end

  def initialize(user_request)
    @user_request = user_request
    @current_booking_detail = @user_request.try(:booking_detail)
    @alternate_project_unit = @user_request.alternate_project_unit
    resolve
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

  def resolve
    error_messages = ''
    new_booking_detail = BookingDetail.new(project_unit_id: alternate_project_unit.id, primary_user_kyc_id: current_booking_detail.primary_user_kyc_id, status: 'hold', user_id: current_booking_detail.user_id, manager: current_booking_detail.try(:manager_id), user_kyc_ids: current_booking_detail.user_kyc_ids)
    new_booking_detail_scheme = current_booking_detail.booking_detail_scheme.dup
    new_booking_detail_scheme.project_unit_id = alternate_project_unit.id
    new_booking_detail_scheme.booking_detail_id = new_booking_detail.id
    error_messages = new_booking_detail_scheme.errors.full_messages unless new_booking_detail_scheme.save
    if error_messages.blank?
      error_messages = new_booking_detail.errors.full_messages unless new_booking_detail.save
    end
    # replace and remove
    # current_booking_detail.project_unit.processing_swap_request = true
    current_booking_detail[:swap_request_initiated] = true
    if error_messages.blank?
      current_booking_detail.receipts.desc(:total_amount).each do |old_receipt|
        next unless %w[pending clearance_pending success].include?(old_receipt.status)

        new_receipt = old_receipt.dup
        new_receipt.booking_detail_id = new_booking_detail.id
        new_receipt.project_unit_id = alternate_project_unit.id
        new_receipt.comments = "Receipt generated for Swapped Unit. Original Receipt ID: #{old_receipt.id}"
        old_receipt.comments ||= ''
        old_receipt.comments += "Unit Swapped by user. Original Unit ID: #{user_request.project_unit_id} So cancelling these receipts"
        unless new_receipt.save
          error_messages = new_receipt.errors.full_messages
          break
        end
        unless old_receipt.cancel!
          error_messages = new_receipt.errors.full_messages
          break
        end
      end
      # booking detail object will move to blocked or appropriate state on its own
      alternate_project_unit.set(status: 'blocked')
      new_booking_detail.set(status: 'blocked')
      # change state of alternate project unit to blocked
    end
    if error_messages.blank?
      user_request.project_unit.make_available
      error_messages = user_request.project_unit.errors.full_messages unless user_request.project_unit.save
    end
    if error_messages.blank?
      send_email if user_request.user.booking_portal_client.email_enabled?
      send_sms
      current_booking_detail.swapped!
      # remove from eveywhere else too
      # current_booking_detail.unset(:swap_request_initiated)
    else
      user_request.reason_for_failure = error_messages
      current_booking_detail.swap_rejected!
    end
  end
end

# def swap # extra code just kept for backup , will be deleted
# if(@alternate_project_unit.status == "available" || (@alternate_project_unit.status == "hold" && @alternate_project_unit.user_id == @project_unit.user_id)) #

# existing_receipts = @project_unit.receipts.in(status:["success", "clearance_pending", "pending"]).asc(:total_amount)
# existing_receipts_json = existing_receipts.as_json
# existing_receipts.each do |receipt|
# receipt.project_unit_id = nil
# receipt.comments ||= ""
# receipt.comments += "Unit Swapped by user. Original Unit ID: #{@project_unit.id.to_s} So cancelling these receipts"
# receipt.swap_request_initiated = true
# receipt.event = "cancel"
# receipt.save
# end

# primary_user_kyc = @project_unit.primary_user_kyc
# booking_detail = @project_unit.booking_detail
# user_kycs = @project_unit.user_kycs
# user = @project_unit.user

# @project_unit.processing_swap_request = true
# @project_unit.make_available
# @project_unit.save!

# booking_detail.reload
# booking_detail[:swap_request_initiated] = true
# booking_detail.status = "swapped"
# booking_detail.save

# @alternate_project_unit.primary_user_kyc_id = primary_user_kyc.id
# @alternate_project_unit.user_kycs = user_kycs
# @alternate_project_unit.status = "hold"
# @alternate_project_unit.user = user
# @alternate_project_unit.selected_scheme_id = @project_unit.scheme.id
# @alternate_project_unit.save!

#     existing_receipts_json.each do |old_receipt|
#       # cloned_json = old_receipt.clone
#       # cloned_json.delete "receipt_id"
#       # cloned_json.delete "_id"
#       # cloned_json.delete "order_id"
#       # cloned_json.delete "booking_detail_id"
#       # cloned_json.delete "created_at"
#       # cloned_json.delete "updated_at"

#       new_receipt = Receipt.new(cloned_json)
#       new_receipt.comments = "Receipt generated for Swapped Unit. Original Receipt ID: #{old_receipt["id"].to_s}"
#       new_receipt.project_unit = @alternate_project_unit
#       new_receipt.swap_request_initiated = true
#       unless new_receipt.save
#         Rails.logger.info(" ProjectUnitSwapService Receipt Issue : #{new_receipt.errors.as_json}")
#       end
#     end
#     booking_detail.unset(:swap_request_initiated)
#     {status: "success"}
#   else
#     {status: "error", error: "#{@alternate_project_unit.name} is #{@alternate_project_unit.status}"}
#   end
# end
