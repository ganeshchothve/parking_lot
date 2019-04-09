# UserRequests::CancellationProcess
module UserRequests
  class CancellationProcess
    include Sidekiq::Worker
    attr_reader :user_request, :booking_detail

    def perform(user_request_id)
      @user_request = UserRequest.where(_id: user_request_id).first
      @booking_detail = user_request.try(:booking_detail)
      if @booking_detail && @booking_detail.cancelling?
        resolve
      else
        reject_user_request([], [], 'Booking Is not available for cancellation.')
      end
    end

    # This function updates the status of current receipts according to requirement
    def update_receipts(old_receipts_arr, new_receipts_arr, error_messages)
      booking_detail.receipts.in(status: %w[pending clearance_pending success] ).each do |receipt|
        old_receipts_arr << [receipt.id, receipt.status]
        case receipt.status
        when 'success'
          unless receipt.available_for_refund!
            error_messages = receipt.errors.full_messages
            break
          end
        when 'clearance_pending'
          # move to state machine receipt
          if receipt.cancel!
            new_receipt = receipt.dup
            new_receipt.assign_attributes(booking_detail: nil, project_unit: nil, status: 'clearance_pending')
            unless new_receipt.save
              error_messages = new_receipt.errors.full_messages
              break
            end
            new_receipts_arr << new_receipt
          else

            error_messages = receipt.errors.full_messages
            break
          end
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
      update_receipts(old_receipts_arr, new_receipts_arr, error_messages)

      if error_messages.blank?
        booking_detail.cancel!
      else
        reject_user_request(old_receipts_arr, new_receipts_arr, error_messages)
      end
    end
  end
end
