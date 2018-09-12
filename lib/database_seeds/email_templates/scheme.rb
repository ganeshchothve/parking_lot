module DatabaseSeeds
  module EmailTemplates
    module Scheme
      def self.seed client_id
        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "Scheme", name: "scheme_draft", subject: "Scheme <%= self.name %> Requested", content: '<%= self.to_json %>')  if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, name: "scheme_draft").blank?
        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "Scheme", name: "scheme_approved", subject: "Scheme <%= self.name %> Approved", content: '<%= self.to_json %>')  if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, name: "scheme_approved").blank?
        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "Scheme", name: "scheme_disabled", subject: "Scheme <%= self.name %> Disabled", content: '<%= self.to_json %>')  if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, name: "scheme_disabled").blank?
      end
    end
  end
end
