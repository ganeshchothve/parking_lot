module ChannelPartnerStateMachine
  extend ActiveSupport::Concern
  included do
    include AASM
    attr_accessor :event

    aasm column: :status, whiny_transitions: false do
      state :inactive, initial: true
      state :active, :pending, :rejected

      event :submit_for_approval, after: %i[after_submit_for_approval] do
        transitions from: :inactive, to: :pending, if: :can_send_for_approval?
        transitions from: :rejected, to: :pending, if: :can_send_for_approval?
      end

      event :approve, after: %i[send_notification] do
        transitions from: :pending, to: :active
      end

      event :reject, after: %i[send_notification] do
        transitions from: :pending, to: :rejected
      end

      # event :disable, after: %i[send_notification]  do
      #   transitions from: :active, to: :inactive
      # end
    end

    def can_send_for_approval?
      valid = self.valid?
      ChannelPartner::DOCUMENT_TYPES.each do |dt|
        valid = valid && self.assets.where(document_type: dt).present?
      end
      valid
    end

    def after_submit_for_approval
      self.set( status_change_reason: nil )
      # send_notification
    end

    def send_notification
      template_name = "channel_partner_status_#{self.status}"
      template = Template::EmailTemplate.where(name: template_name).first
      recipients = [self.associated_user]
      recipients << self.manager if self.manager.present?
      recipients << self.manager.manager if self.manager.try(:manager).present?

      if template.present?
        email = Email.create!({
          booking_portal_client_id: self.associated_user.booking_portal_client_id,
          email_template_id: template.id,
          recipients: recipients.flatten,
          triggered_by_id: self.id,
          triggered_by_type: self.class.to_s
        })
        email.sent!
      end
    end
  end
end