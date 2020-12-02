module InvoiceStateMachine
  extend ActiveSupport::Concern
  included do
    include AASM
    attr_accessor :event

    aasm column: :status, whiny_transitions: false do
      state :draft, initial: true
      state :pending_approval
      state :approved, :rejected

      event :raise, after: :after_pending_approval_event do
        transitions from: :draft, to: :pending_approval
      end

      event :approve, after: :after_approved_event do
        transitions from: :pending_approval, to: :approved, if: :can_approve?
      end

      event :reject, after: :after_rejected_event do
        transitions from: :pending_approval, to: :rejected
      end
    end

    def after_pending_approval_event
      self.raised_date = Time.now
    end
    def after_approved_event
      self.processing_date = Time.now
      self.approved_date = Time.now
      reject_pending_deductions
    end
    def after_rejected_event
      self.processing_date = Time.now
      self.net_amount = 0
      reject_pending_deductions
    end

    def reject_pending_deductions
      self.incentive_deduction.rejected! if self.incentive_deduction? && self.incentive_deduction.pending_approval?
    end

    def can_approve?
      # TODO: check if cheque details are present
      true
    end

    before_validation do |invoice|
      _event = invoice.event.to_s
      invoice.event = nil
      if _event.present? && (invoice.aasm.current_state.to_s != _event.to_s)
        if invoice.send("may_#{_event.to_s}?")
          invoice.aasm.fire(_event.to_sym)
          invoice.save
        else
          invoice.errors.add(:status, 'transition is invalid')
        end
      end
    end

  end
end
