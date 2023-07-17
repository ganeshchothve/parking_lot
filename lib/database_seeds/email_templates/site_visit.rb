module DatabaseSeeds
  module EmailTemplates
    module SiteVisit
      def self.seed(project_id, client_id)

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "SiteVisit", name: "site_visit_scheduled", subject: "Site Visit Scheduled", content: '<div class="card w-100">
          <div class="card-body">
            <p>Dear <%= self.lead.name %>,</p>
            <p>
              Your site visit for <%= project.name %> is scheduled at <%= I18n.l(self.scheduled_on) %>
              <br>
              Please show this <%= I18n.t("mongoid.attributes.site_visit.code") %>: <%= self.code %> at the project site.
            </p>
          </div>
        </div>') if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "site_visit_scheduled").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "SiteVisit", name: "site_visit_conducted", subject: "Site Visit Scheduled", content: '<div class="card w-100">
          <div class="card-body">
            <p>Dear <%= self.lead.name %>,</p>
            <p>
              Your site visit for <%= project.name %> was successfully conducted.
            </p>
          </div>
        </div>') if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "site_visit_conducted").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "SiteVisit", name: "site_visit_cancelled", subject: "Site Visit Scheduled", content: '<div class="card w-100">
          <div class="card-body">
            <p>Dear <%= self.lead.name %>,</p>
            <p>
              Your site visit for <%= project.name %> scheduled on <%= I18n.l(self.scheduled_on) %> is cancelled.
            </p>
          </div>
        </div>') if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "site_visit_cancelled").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "SiteVisit", name: "site_visit_inactive", subject: "Site Visit Scheduled", content: '<div class="card w-100">
          <div class="card-body">
            <p>Dear <%= self.lead.name %>,</p>
            <p>
              Your site visit for <%= project.name %> scheduled on <%= I18n.l(self.scheduled_on) %> has been marked inactive.
              <br>
              Please schedule a new site visit.
            </p>
          </div>
        </div>') if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "site_visit_inactive").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "SiteVisit", name: "site_visit_rescheduled", subject: "Site Visit Scheduled", content: '<div class="card w-100">
          <div class="card-body">
            <p>Dear <%= self.lead.name %>,</p>
            <p>
              Your site visit for <%= project.name %> is rescheduled at <%= I18n.l(self.scheduled_on) %>
              <br>
              Please show this <%= I18n.t("mongoid.attributes.site_visit.code") %>: <%= self.code %> at the project site.
            </p>
          </div>
        </div>') if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "site_visit_rescheduled").blank?

      end
    end
  end
end
