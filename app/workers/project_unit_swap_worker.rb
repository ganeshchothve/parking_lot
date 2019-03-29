class ProjectUnitSwapWorker
  include Sidekiq::Worker
  attr_accessor :user_request, :current_booking_detail, :alternate_project_unit, :current_project_unit

  def perform(user_request_id)
    @user_request = UserRequest.find(user_request_id)
    @current_booking_detail = @user_request.try(:booking_detail)
    @alternate_project_unit = @user_request.alternate_project_unit
    @current_project_unit = @current_booking_detail.project_unit
    resolve
  end

  def update_receipts(error_messages, new_booking_detail)
    current_booking_detail.receipts.desc(:total_amount).each do |old_receipt|
      next unless %w[pending clearance_pending success].include?(old_receipt.status)

      # TODO: :Error Handling for receipts remaining #SANKET
      new_receipt = old_receipt.dup
      new_receipt.booking_detail_id = new_booking_detail.id
      new_receipt.project_unit_id = alternate_project_unit.id
      new_receipt.comments = "Receipt generated for Swapped Unit. Original Receipt ID: #{old_receipt.id}"
      old_receipt.comments ||= ''
      old_receipt.comments += "Unit Swapped by user. Original Unit ID: #{current_project_unit.id} So cancelling these receipts"
      unless new_receipt.save
        error_messages = new_receipt.errors.full_messages
        break
      end
      unless old_receipt.cancel!
        error_messages = new_receipt.errors.full_messages
        break
      end
    end
    error_messages
  end

  def create_booking_detail
    BookingDetail.new(project_unit_id: alternate_project_unit.id, primary_user_kyc_id: current_booking_detail.primary_user_kyc_id, status: 'hold', user_id: current_booking_detail.user_id, manager: current_booking_detail.try(:manager_id), user_kyc_ids: current_booking_detail.user_kyc_ids, parent_booking_detail_id: current_booking_detail.id)
  end

  def create_booking_detail_scheme(new_booking_detail)
    new_booking_detail_scheme = current_booking_detail.booking_detail_scheme.dup
    new_booking_detail_scheme.project_unit_id = alternate_project_unit.id
    new_booking_detail_scheme.booking_detail_id = new_booking_detail.id
    new_booking_detail_scheme
  end

  # When processing fails the old project unit is restored to its previous state, booking detail is marked as swap rejected and then appropriate state, user request is rejected
  def reject_user_request(error_messages, alternate_project_unit_status, new_booking_detail = nil, new_booking_detail_scheme = nil)
    new_booking_detail_scheme.delete if new_booking_detail_scheme.present?
    new_booking_detail.delete if new_booking_detail.present?
    alternate_project_unit.set(status: alternate_project_unit_status) unless alternate_project_unit.status == alternate_project_unit_status
    user_request.set(reason_for_failure: error_messages)
    current_booking_detail.swap_rejected!
  end

  # This method tries to resolve a user_request and marks it as resolved if the processing is successful otherwise rejects the request. New booking detail object is created with new booking detail scheme. All the old receipts are marked as cancelled and new receipts are attached to the new booking detail object. Then the old project unit is made available and new project unit and booking detail are blocked. Also old booking detail object is marked swapped
  def resolve
    error_messages = ''
    alternate_project_unit_status = alternate_project_unit.status
    new_booking_detail = create_booking_detail
    new_booking_detail_scheme = create_booking_detail_scheme(new_booking_detail)
    error_messages = new_booking_detail_scheme.errors.full_messages unless new_booking_detail_scheme.save
    if error_messages.blank?
      error_messages = new_booking_detail.errors.full_messages unless new_booking_detail.save
    end

    if error_messages.blank?
      error_messages = update_receipts(error_messages, new_booking_detail)
    end
    if error_messages.blank?
      # TODO: : booking detail object and alternate project unit will move to blocked or appropriate state on its own
      alternate_project_unit.set(status: 'blocked')
      new_booking_detail.set(status: 'blocked')
      current_project_unit.make_available
      error_messages = current_project_unit.errors.full_messages unless current_project_unit.save
    end
    error_messages.blank? ? current_booking_detail.swapped! : reject_user_request(error_messages, alternate_project_unit_status, new_booking_detail, new_booking_detail_scheme)
  end
end
