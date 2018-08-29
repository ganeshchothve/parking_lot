module DatabaseSeeds
  module EmailTemplates
    module UserRequest
      def self.seed client_id
        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "UserRequest", name: "cancellation_request_created", subject: "Cancellation Requested for Unit: <%= self.project_unit.name %>", content: '<%= self.project_unit.name %>') if ::Template::EmailTemplate.where(name: "cancellation_request_created").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "UserRequest", name: "cancellation_request_resolved", subject: "Cancellation Request for Unit: <%= self.project_unit.name %> Resolved", content: '<%= self.project_unit.name %>') if ::Template::EmailTemplate.where(name: "cancellation_request_resolved").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "UserRequest", name: "swap_request_created", subject: "swap Requested for Unit: <%= self.project_unit.name %>", content: '<%= self.project_unit.name %>') if ::Template::EmailTemplate.where(name: "swap_request_created").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "UserRequest", name: "swap_request_resolved", subject: "swap Request for Unit: <%= self.project_unit.name %> Resolved", content: '<%= self.project_unit.name %>') if ::Template::EmailTemplate.where(name: "swap_request_resolved").blank?
      end
    end
  end
end
