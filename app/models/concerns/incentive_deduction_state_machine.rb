module IncentiveDeductionStateMachine
  extend ActiveSupport::Concern
  included do
    include AASM
    attr_accessor :event

    aasm column: :status, whiny_transitions: false do
      state :draft, initial: true
      state :pending_approval
      state :approved, :rejected

      event :pending_approval, after: :after_pending_approval_event do
        transitions from: :draft, to: :pending_approval
        transitions from: :rejected, to: :pending_approval
      end

      event :approved, after: :after_approved_event do
        transitions from: :pending_approval, to: :approved
      end

      event :rejected, after: :after_rejected_event do
        transitions from: :pending_approval, to: :rejected
      end
    end

    def after_pending_approval_event
      _invoice = self.invoice
      # Reject deductions if invoice is already processed.
      if _invoice.status.in?(%w(approved rejected))
        self.rejected!
      end
    end
    def after_approved_event
      _invoice = self.invoice
      _invoice.net_amount = _invoice.amount - self.amount
      _invoice.save
    end
    def after_rejected_event
    end

    before_validation do |deduction|
      _event = deduction.event.to_s
      deduction.event = nil
      if _event.present? && (deduction.aasm.current_state.to_s != _event.to_s)
        if deduction.send("may_#{_event.to_s}?")
          deduction.aasm.fire(_event.to_sym)
          deduction.save
        else
          deduction.errors.add(:status, 'transition is invalid')
        end
      end
    end

    after_save do |deduction|
      if deduction.draft? && deduction.assets.present? && deduction.assets.first.file.try(:url).present?
        deduction.pending_approval!
      end
    end
  end
end
