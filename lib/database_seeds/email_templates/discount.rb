module DatabaseSeeds
  module EmailTemplates
    module Discount
      def self.seed client_id
        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "Discount", name: "discount_draft", subject: "Discount <%= self.name %> Requested", content: '<%= self.to_json %>')  if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, name: "discount_draft").blank?
        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "Discount", name: "discount_approved", subject: "Discount <%= self.name %> Approved", content: '<%= self.to_json %>')  if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, name: "discount_approved").blank?
        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "Discount", name: "discount_disabled", subject: "Discount <%= self.name %> Disabled", content: '<%= self.to_json %>')  if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, name: "discount_disabled").blank?
      end
    end
  end
end
