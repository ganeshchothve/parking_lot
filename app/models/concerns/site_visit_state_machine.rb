module SiteVisitStateMachine
  extend ActiveSupport::Concern
  included do
    include AASM

    attr_accessor :event, :approval_event
    field :status, type: String, default: 'scheduled'
    field :approval_status, type: String, default: 'pending'

    # SiteVisit status state machine
    aasm :status, column: :status, whiny_transitions: false do
      state :scheduled, initial: true
      state :pending, :missed, :conducted

      event :conduct, after: %i[send_notification] do
        transitions from: :scheduled, to: :conducted, if: :can_conduct?
        transitions from: :pending, to: :conducted, if: :can_conduct?
      end
    end

    def can_schedule?
      scheduled_on >= Time.now
    end

    def can_conduct?
      scheduled_on < Time.now
    end

    def send_notification
      template_name = "site_visit_#{self.status}_notification"
      # TODO: Send Broadcast message via notification, in-app, Email, etc
    end


    # State machine for approval status maintained on a separate field
    aasm :approval_status, column: :approval_status, whiny_transitions: false, namespace: :verification do
      state :pending, initial: true
      state :approved, :rejected

      event :approve, before: :mark_conducted, after: %i[send_approval_status_notification] do
        transitions from: :pending, to: :approved, if: :can_approve?
        transitions from: :rejected, to: :approved, if: :can_approve?
      end

      event :reject, after: %i[send_approval_status_notification] do
        transitions from: :pending, to: :rejected, if: :can_reject?
      end
    end

    def can_approve?
      scheduled_on < Time.now
    end

    def can_reject?
      scheduled_on < Time.now
    end

    def mark_conducted
      self.conduct if self.may_conduct?
    end

    def send_approval_status_notification
      template_name = "site_visit_approval_status_#{self.approval_status}_notification"
      # TODO: Send Broadcast message via notification, in-app, Email, etc
    end
  end
end
