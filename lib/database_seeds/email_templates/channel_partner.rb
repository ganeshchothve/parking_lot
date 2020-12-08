module DatabaseSeeds
  module EmailTemplates
    module ChannelPartner
      def self.seed(client_id)
        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "ChannelPartner", name: "channel_partner_status_active", subject: "Account has been approved", content: '<div class="card w-100">You account has been approved.</div>') if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, name: "channel_partner_status_active").blank?
        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "ChannelPartner", name: "channel_partner_status_rejected", subject: "Account has been rejected", content: '<div class="card w-100">You account has been rejected for following reason - <%= self.status_change_reason %>.</div>') if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, name: "channel_partner_status_rejected").blank?
      end
    end
  end
end
