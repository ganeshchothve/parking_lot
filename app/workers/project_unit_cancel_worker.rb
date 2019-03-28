class ProjectUnitCancelWorker
  include Sidekiq::Worker
  attr_reader :user_request, :booking_detail

  def perform(user_request_id)
    @user_request = UserRequest.find(user_request_id)
    @booking_detail = user_request.try(:booking_detail)
    resolve
  end

  # This function updates the status of current receipts according to requirement
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

  # This function checks if the current project unit can be made available
  def can_update_project_unit_to_available?
    make_project_unit_available = ProjectUnit.booking_stages.include?(booking_detail.project_unit.status) && (user_request.user_id == booking_detail.project_unit.user_id)
  end

  # This function updates the current project unit to available
  def update_project_unit_to_available(_error_messages)
    project_unit = booking_detail.project_unit
    project_unit.processing_user_request = true
    project_unit.make_available
    error_messages = project_unit.errors.full_messages unless project_unit.save
  end

  # This function restores the status of the receipts if processing of the cancellation request fails
  def revert_updated_receipts(old_receipts_arr, new_receipts_arr)
    old_receipts_arr.each do |a|
      receipt = Receipt.find(a[0])
      receipt.set(status: a[1])
    end
    new_receipts_arr.each(&:destroy)
  end

  def reject_user_request(old_receipts_arr, new_receipts_arr, error_messages)
    revert_updated_receipts(old_receipts_arr, new_receipts_arr)
    user_request.set(reason_for_failure: error_messages)
    booking_detail.cancellation_rejected!
  end

  # This function resolves the cancellation request raised by user
  def resolve
    old_receipts_arr = []
    new_receipts_arr = []
    error_messages = ''
    error_messages = update_receipts(old_receipts_arr, new_receipts_arr, error_messages)
    if error_messages.blank?
      can_update_project_unit_to_available? ? error_messages = update_project_unit_to_available(error_messages) : error_messages = ['Project Unit unavailable']
    end
    error_messages.blank? ? booking_detail.cancel! : reject_user_request(old_receipts_arr, new_receipts_arr, error_messages)
  end
end
