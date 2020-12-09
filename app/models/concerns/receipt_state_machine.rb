module ReceiptStateMachine
  extend ActiveSupport::Concern
  included do
    include AASM
    attr_accessor :event

    aasm column: :status, whiny_transitions: false do
      state :pending, initial: true
      state :success, :clearance_pending, :failed, :available_for_refund, :refunded
      state :cancellation_requested, :cancelling, :cancelled, :cancellation_rejected


      event :pending, after: %i[moved_to_clearance_pending send_pending_notification] do
        transitions from: :pending, to: :pending
      end

      event :clearance_pending, after: %i[moved_to_success_if_online lock_lead] do
        transitions from: :pending, to: :clearance_pending, if: :can_move_to_clearance?
        transitions from: :clearance_pending, to: :clearance_pending
      end

      event :success, after: %i[change_booking_detail_status send_success_notification lock_lead] do
        transitions from: :success, to: :success
        # receipt moves from pending to success when online payment is made.
        transitions from: :clearance_pending, to: :success
        transitions from: :available_for_refund, to: :success
        transitions from: :cancellation_rejected, to: :success
      end

      event :available_for_refund do
        transitions from: :available_for_refund, to: :available_for_refund
        transitions from: :success, to: :available_for_refund, if: :can_available_for_refund? # For booking cancellation
        transitions from: :cancelled, to: :available_for_refund, success: %i[send_booking_detail_to_under_negotiation]
      end

      event :cancelling do
        transitions from: :cancellation_requested, to: :cancelling
      end

      event :cancellation_rejected, after: %i[move_to_success] do
        transitions from: :cancellation_requested, to: :cancellation_rejected
      end

      event :refunded, after: %i[send_notification] do
        transitions from: :refunded, to: :refunded
      end

      event :refund do
        transitions from: :available_for_refund, to: :refunded
      end

      event :failed, after: :send_booking_detail_to_under_negotiation do
        transitions from: :pending, to: :failed, if: :can_mark_failed?
        transitions from: :clearance_pending, to: :failed
        transitions from: :failed, to: :failed
      end

      event :cancellation_requested do
        transitions from: :success, to: :cancellation_requested
      end

      event :cancel do
        transitions from: :pending, to: :cancelled, if: :user_request_initiated?
        transitions from: :success, to: :cancelled, if: :swap_request_initiated?
        transitions from: :clearance_pending, to: :cancelled, if: :user_request_initiated?
        transitions from: :cancelling, to: :cancelled, success: %i[move_to_available_for_refund]
      end
    end

    def lock_lead
      if (self.online? && self.status == 'success') || (self.offline? && %w(pending clearance_pending success).include?(self.status))
        user.unblock_lead!(true)
      end
    end

    def swap_request_initiated?
      return booking_detail.swapping? if booking_detail
      false
    end

    def can_available_for_refund?
      return (booking_detail.blank? || booking_detail.cancelling?) if booking_detail

      false
    end

    def can_move_to_clearance?
      persisted? || project_unit_id.present?
    end

    def move_to_available_for_refund
      available_for_refund!
    end

    def move_to_success
      success!
    end

    def moved_to_success_if_online
      if payment_mode == 'online'
        success!
      else
        change_booking_detail_status
        send_notification
      end
    end

    def send_success_notification
      if %i[success cancellation_rejected].exclude?(self.aasm.from_state)
        send_notification
      end
    end

    def send_pending_notification
      if payment_mode != 'online' && status == 'pending'
        send_notification
      end
    end

    def user_request_initiated?
      return (booking_detail.swapping? || booking_detail.cancelling?) if booking_detail
      false
    end

    def change_booking_detail_status
      if booking_detail
        booking_detail.send("after_#{booking_detail.status}_event")
      end
    end

    def send_booking_detail_to_under_negotiation
      change_booking_detail_status
      send_notification if %i[pending clearance_pending cancelled].include?(self.aasm.from_state)
    end
    #
    # When Receipt is created by admin except channel partner then it's direcly moved in clearance pending.
    #
    def moved_to_clearance_pending
      if payment_mode != 'online'
        unless ((User::BUYER_ROLES).include?(self.creator.role))||(self.creator.role == 'channel_partner' && !self.creator.premium?)
          self.clearance_pending!
        end
      end
    end

    #
    # Only online pening payments can mark as failed.
    #
    #
    # @return [Boolean]
    #
    def can_mark_failed?
      !new_record? && payment_mode == 'online'
    end

    def send_notification
      Notification::Receipt.new(self.id, { status: [self.status_was, self.status] }, { record: self } ).execute

      # TODO - Remove hardcoded from value & save it on client. This is a test entry for whatsapp message.
      # Actual messages will be added via templates on client requests & triggered appropriately.
      if self.user.booking_portal_client.whatsapp_enabled?
        whatsapp_template = Template::WhatsappTemplate.where(project_id: self.project_id, name: 'receipt_success').first
        if whatsapp_template.present?
          Whatsapp.create!(project_id: self.project_id, to: self.user.phone, triggered_by: self, booking_portal_client: self.user.booking_portal_client, whatsapp_template: whatsapp_template, from: "+16413231111")
        end
      end
    end
  end
end
