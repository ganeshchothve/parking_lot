module DatabaseSeeds
  module EmailTemplates
    module Lead
      def self.seed project_id, client_id
        Template::EmailTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "Lead", name: "lead_create", subject: "New lead has been created in the system - <%= self.name %>", content: 'New lead has been created in the system - <%= self.name %>')  if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "lead_create").blank?
        Template::EmailTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "Lead", name: "lead_update", subject: "Lead stage updated - <%= self.name %>", content: 'Lead(<%= self.name %>) stage has been updated to <%= self.stage %>')  if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "lead_update").blank?
      end
    end
  end
end
