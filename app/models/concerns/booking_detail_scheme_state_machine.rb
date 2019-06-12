module BookingDetailSchemeStateMachine
  extend ActiveSupport::Concern
  included do
    include AASM
    attr_accessor :event
    aasm column: :status, whiny_transitions: false do
      state :draft, initial: true
      state :approved, :rejected

      event :draft, after: :after_draft_event do
        transitions from: :draft, to: :draft
        transitions from: :approved, to: :draft
      end

      event :approved, after: :after_approved_event do
        transitions from: :approved, to: :approved
        transitions from: :draft, to: :approved, if: :booking_detail_present?
      end

      event :rejected ,after: :after_rejected_event do
        transitions from: :rejected, to: :rejected
        transitions from: :draft, to: :rejected
        transitions from: :approved, to: :rejected, if: :other_approved_scheme_present?
      end
    end

    def booking_detail_present?
      booking_detail.present?
    end

    def editable_payment_adjustments_present?
      editable_payment_adjustments.count > 0
    end

    def other_approved_scheme_present?
      BookingDetailScheme.where(project_unit_id: project_unit_id, user_id: user_id, status: 'approved').count > 1
    end

    def after_draft_event
      booking_detail.under_negotiation! if !(%w[hold under_negotiation].include?booking_detail.status)
      send_email_as_draft
    end

    # after booking_detail_scheme is rejected, move booking detail to scheme_rejected state
    def after_rejected_event
      booking_detail.scheme_rejected!
    end
    # after booking_detail_scheme is approved, move booking detail to scheme_approved state
    def after_approved_event
      booking_detail.scheme_approved!
      send_email_as_approved
    end

    def send_email_as_approved
      if booking_detail.project_unit.booking_portal_client.email_enabled?
        begin
          email = Email.create!(
            booking_portal_client_id: booking_detail.project_unit.booking_portal_client_id,
            email_template_id: Template::EmailTemplate.find_by(name: 'booking_detail_scheme_approved').id,
            cc: [booking_detail.project_unit.booking_portal_client.notification_email],
            recipients: [booking_detail_scheme.created_by, booking_detail_scheme.approved_by],
            cc_recipients: (booking_detail_scheme.created_by.manager_id.present? ? [booking_detail_scheme.created_by.manager] : []),
            triggered_by_id: booking_detail_scheme.id,
            triggered_by_type: booking_detail_scheme.class.to_s
          )
          email.sent!
        rescue StandardError
          'booking detail scheme approved by is nil'
        end
      end
    end
    def send_email_as_draft
      if self.created_by_user && booking_detail.project_unit.booking_portal_client.email_enabled?
        begin
          email = Email.create!(
            booking_portal_client_id: booking_detail.project_unit.booking_portal_client_id,
            email_template_id: Template::EmailTemplate.find_by(name: 'booking_detail_scheme_draft').id,
            cc: [booking_detail.project_unit.booking_portal_client.notification_email],
            recipients: [booking_detail_scheme.created_by],
            cc_recipients: (booking_detail_scheme.created_by.manager_id.present? ? [booking_detail_scheme.created_by.manager] : []),
            triggered_by_id: booking_detail_scheme.id,
            triggered_by_type: booking_detail_scheme.class.to_s
          )
          email.sent!
        rescue StandardError
          'booking_detail under_negotiation is nil'
        end
      end
    end
  end
end
