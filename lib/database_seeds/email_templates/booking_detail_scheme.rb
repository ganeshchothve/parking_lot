# DatabaseSeeds::EmailTemplates::BookingDetailScheme.seed(Client.last.id)
module DatabaseSeeds
  module EmailTemplates
    module BookingDetailScheme
      def self.seed client_id
        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "BookingDetailScheme", name: "booking_detail_scheme_draft", subject: "Scheme updated for <%= self.project_unit.name %>", content: '<%= self.to_json %>')  if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, name: "booking_detail_scheme_draft").blank?
        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "BookingDetailScheme", name: "booking_detail_scheme_approved", subject: "Scheme for <%= self.project_unit.name %> Approved", content: '<%= self.to_json %>')  if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, name: "booking_detail_scheme_approved").blank?
      end
    end
  end
end
