module BookingDetailStateMachine
  extend ActiveSupport::Concern
  included do
    include AASM
    attr_accessor :event
    aasm column: :status, whiny_transitions: false do
      # state :filter, initial: true
      # state :tower, :project_unit, :user_kyc
      # state :hold, :blocked, :booked_tentative, :booked_confirmed, :under_negotiation, :scheme_rejected, :scheme_approved
      # state :swap_requested, :swapping, :swapped, :swap_rejected
      # state :cancellation_requested, :cancelling, :cancelled, :cancellation_rejected

      state :hold, initial: true
      state :blocked, :booked_tentative, :booked_confirmed, :under_negotiation, :scheme_rejected, :scheme_approved

      # event :filter do
      #   transitions from: :filter, to: :filter
      # end

      # event :tower do
      #   transitions from: :tower, to: :tower
      #   transitions from: :filter, to: :tower
      # end

      # event :project_unit do
      #   transitions from: :project_unit, to: :project_unit
      #   transitions from: :tower, to: :project_unit
      # end

      # event :user_kyc do
      #   transitions from: :user_kyc, to: :user_kyc
      #   transitions from: :project_unit, to: :user_kyc
      # end

      event :hold do
        transitions from: :hold, to: :hold
        # transitions from: :user_kyc, to: :hold
      end

      event :under_negotiation, after_commit: :push_to_scheme_approved, before: :bef_under_negotiation do
        transitions from: :under_negotiation, to: :under_negotiation
        transitions from: :hold, to: :under_negotiation
      end

      event :scheme_approved, after: :aft_scheme_approved do
        transitions from: :scheme_approved, to: :scheme_approved
        transitions from: :under_negotiation, to: :scheme_approved
      end

      event :scheme_rejected do
        transitions from: :scheme_rejected, to: :scheme_rejected
        transitions from: :under_negotiation, to: :scheme_rejected
      end

      event :blocked, after: :aft_blocked do
        transitions from: :blocked, to: :blocked
        transitions from: :scheme_approved, to: :blocked, guard: :can_blocked?
        # transitions from: :swap_rejected, to: :blocked
        # transitions from: :cancellation_rejected, to: :blocked
      end

      event :booked_tentative, after: :aft_booked_tentative do
        transitions from: :booked_tentative, to: :booked_tentative
        transitions from: :blocked, to: :booked_tentative, guard: :can_booked_tentative?
      end

      event :booked_confirmed do
        transitions from: :booked_confirmed, to: :booked_confirmed
        transitions from: :booked_tentative, to: :booked_confirmed, guard: :can_booked_confirmed?
      end

      # event :swap_requested do
      #   transitions from: :swap_requested, to: :swap_requested
      #   transitions from: :blocked, to: :swap_requested
      #   transitions from: :booked_tentative, to: :swap_requested
      #   transitions from: :booked_confirmed, to: :swap_requested
      # end

      # event :swapping do
      #   transitions from: :swapping, to: :swapping
      #   transitions from: :swap_requested, to: :swapping
      # end

      # event :swapped do
      #   transitions from: :swapped, to: :swapped
      #   transitions from: :swapping, to: :swapped
      # end

      # event :swap_rejected do
      #   transitions from: :swap_rejected, to: :swap_rejected
      #   transitions from: :swap_requested, to: :swap_rejected
      # end

      # event :cancellation_requested do
      #   transitions from: :cancellation_requested, to: :cancellation_requested
      #   transitions from: :blocked, to: :cancellation_requested
      #   transitions from: :booked_tentative, to: :cancellation_requested
      #   transitions from: :booked_confirmed, to: :cancellation_requested
      # end

      # event :cancelling do
      #   transitions from: :cancelling, to: :cancelling
      #   transitions from: :cancellation_requested, to: :cancelling
      # end

      # event :cancelled do
      #   transitions from: :cancelled, to: :cancelled
      #   transitions from: :cancelling, to: :cancelled
      # end

      # event :cancellation_rejected do
      #   transitions from: :cancellation_rejected, to: :cancellation_rejected
      #   transitions from: :cancellation_requested, to: :cancellation_rejected
      # end
    end

    def bef_under_negotiation
      pubs = ProjectUnitBookingService.new(self.project_unit.id)
      booking_detail_scheme = pubs.create_or_update_booking_detail_scheme self if self.booking_detail_schemes.empty?
      booking_detail_scheme.approved! if booking_detail_scheme.present? &&booking_detail_scheme.status != 'approved'
    end

    # This method push booking portal to next state as scheme approved.
    # For this booking detail should be in under_negotiation
    # If booking detail scheme is approved the booking detail in scheme_approved
    # If booking detail scheme is rejected then booking detail must be in scheme rejected
    # If booking detail scheme is draft then booking detail stay in under_negotiation
    def push_to_scheme_approved
      if self.aasm.current_state == :under_negotiation
        if self.booking_detail_scheme.present?
          self.scheme_approved!
        elsif (!self.booking_detail_scheme.present?) && (self.booking_detail_schemes.distinct(:status).include? "rejected")
          self.scheme_rejected!
        end
        _project_unit = self.project_unit
        _project_unit.status = 'blocked'
        _project_unit.save
      else
        self.aft_scheme_approved
      end
    end

    def aft_scheme_approved
      if self.aasm.current_state == :scheme_approved
        self.blocked!
      else
        self.aft_blocked
      end
    end

    def aft_blocked
      if self.aasm.current_state == :blocked
        self.booked_tentative!
      else
        self.aft_booked_tentative
      end
    end

    def aft_booked_tentative
      self.booked_confirmed!
    end

    def can_blocked?
      true if self.receipts.in(status: %w[success clearance_pending]).sum{|receipt| receipt.total_amount} >= self.project_unit.blocking_amount && self.booking_detail_scheme.present?
    end

    def can_booked_tentative?
      true if self.receipts.in(status: %w[success clearance_pending]).sum{|receipt| receipt.total_amount} > self.project_unit.blocking_amount && self.booking_detail_scheme.present?
    end

    def can_booked_confirmed?
      true if self.receipts.in(status: %w[success clearance_pending]).sum{|receipt| receipt.total_amount} >= self.project_unit.booking_price && self.booking_detail_scheme.present?
    end
  end
end
