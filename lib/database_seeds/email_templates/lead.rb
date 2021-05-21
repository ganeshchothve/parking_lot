module DatabaseSeeds
  module EmailTemplates
    module Lead
      def self.seed project_id, client_id
        Template::EmailTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "Lead", name: "lead_create", subject: "New lead has been created in the system - <%= self.name %>", content: 'New lead has been created in the system - <%= self.name %>')  if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "lead_create").blank?
        Template::EmailTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "Lead", name: "lead_update", subject: "Lead stage updated - <%= self.name %>", content: 'Lead(<%= self.name %>) stage has been updated to <%= self.stage %>')  if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "lead_update").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "Lead", name: "payment_link", subject: "Make your first payment", content: '<div class="card w-100">
            <div class="card-body">
              <p>
                Dear <%= self.name %>,
              </p>
              <div class="mb-3"></div>
              <p>
                Please make your first payment by clicking the link below.
              </p>
              <div class="mb-3"></div>
              <a href="<%= self.payment_link %>" target="_blank">Make payment</a>
            </div>
          </div>') if ::Template::EmailTemplate.where(name: "payment_link", project_id: project_id, booking_portal_client_id: client_id).blank?
      end
    end
  end
end
