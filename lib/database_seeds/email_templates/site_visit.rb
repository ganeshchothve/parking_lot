module DatabaseSeeds
  module EmailTemplates
    module SiteVisit
      def self.seed(project_id, client_id)

        #
        # For Customers
        #
        Template::EmailTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "SiteVisit", name: "site_visit_scheduled_to_customer", subject: "Site Visit Scheduled", content: '<div class="card w-100">
          <div class="card-body">
            <p>Dear <%= self.lead.name %>,</p>
            <p>
              Your site visit for <%= project.name %> is scheduled at <%= I18n.l(self.scheduled_on) %>
              <br>
              Please show this <%= I18n.t("mongoid.attributes.site_visit.code") %>: <%= self.code %> at the project site.
            </p>
          </div>
        </div>') if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "site_visit_scheduled_to_customer").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "SiteVisit", name: "site_visit_conducted_to_customer", subject: "Site Visit Conducted", content: '<div class="card w-100">
          <div class="card-body">
            <p>Dear <%= self.lead.name %>,</p>
            <p>
              Your site visit for <%= project.name %> was successfully conducted.
            </p>
          </div>
        </div>') if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "site_visit_conducted_to_customer").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "SiteVisit", name: "site_visit_cancelled_to_customer", subject: "Site Visit Cancelled", content: '<div class="card w-100">
          <div class="card-body">
            <p>Dear <%= self.lead.name %>,</p>
            <p>
              Your site visit for <%= project.name %> scheduled on <%= I18n.l(self.scheduled_on) %> is cancelled.
            </p>
          </div>
        </div>') if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "site_visit_cancelled_to_customer").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "SiteVisit", name: "site_visit_inactive_to_customer", subject: "Site Visit Inactive", content: '<div class="card w-100">
          <div class="card-body">
            <p>Dear <%= self.lead.name %>,</p>
            <p>
              Your site visit for <%= project.name %> scheduled on <%= I18n.l(self.scheduled_on) %> has been marked inactive.
              <br>
              Please schedule a new site visit.
            </p>
          </div>
        </div>') if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "site_visit_inactive_to_customer").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "SiteVisit", name: "site_visit_rescheduled_to_customer", subject: "Site Visit Rescheduled", content: '<div class="card w-100">
          <div class="card-body">
            <p>Dear <%= self.lead.name %>,</p>
            <p>
              Your site visit for <%= project.name %> is rescheduled at <%= I18n.l(self.scheduled_on) %>
              <br>
              Please show this <%= I18n.t("mongoid.attributes.site_visit.code") %>: <%= self.code %> at the project site.
            </p>
          </div>
        </div>') if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "site_visit_rescheduled_to_customer").blank?

        #
        # For Channel Partners
        #
        Template::EmailTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "SiteVisit", name: "site_visit_scheduled_to_channel_partner", subject: "Site Visit Scheduled", content: '<div class="card w-100">
          <div class="card-body">
            <p>Dear <%= self.manager.name %>,</p>
            <p>
              Site visit at <%= project.name %> for <%= lead.name %> is scheduled at <%= I18n.l(self.scheduled_on) %>
              <br>
              Please show this <%= I18n.t("mongoid.attributes.site_visit.code") %>: <%= self.code %> at the project site.
            </p>
          </div>
        </div>') if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "site_visit_scheduled_to_channel_partner").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "SiteVisit", name: "site_visit_conducted_to_channel_partner", subject: "Site Visit Conducted", content: '<div class="card w-100">
          <div class="card-body">
            <p>Dear <%= self.manager.name %>,</p>
            <p>
              Site visit at <%= project.name %> for <%= lead.name %> was successfully conducted.
            </p>
          </div>
        </div>') if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "site_visit_conducted_to_channel_partner").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "SiteVisit", name: "site_visit_cancelled_to_channel_partner", subject: "Site Visit Cancelled", content: '<div class="card w-100">
          <div class="card-body">
            <p>Dear <%= self.manager.name %>,</p>
            <p>
              Site visit at <%= project.name %> for <%= lead.name %>, scheduled on <%= I18n.l(self.scheduled_on) %>, is cancelled.
            </p>
          </div>
        </div>') if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "site_visit_cancelled_to_channel_partner").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "SiteVisit", name: "site_visit_inactive_to_channel_partner", subject: "Site Visit Inactive", content: '<div class="card w-100">
          <div class="card-body">
            <p>Dear <%= self.manager.name %>,</p>
            <p>
              Site visit at <%= project.name %> for <%= lead.name %>, scheduled on <%= I18n.l(self.scheduled_on) %>, has been marked inactive.
              <br>
              Please schedule a new site visit.
            </p>
          </div>
        </div>') if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "site_visit_inactive_to_channel_partner").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "SiteVisit", name: "site_visit_rescheduled_to_channel_partner", subject: "Site Visit Rescheduled", content: '<div class="card w-100">
          <div class="card-body">
            <p>Dear <%= self.manager.name %>,</p>
            <p>
              Site visit at <%= project.name %> for <%= lead.name %> is rescheduled at <%= I18n.l(self.scheduled_on) %>
              <br>
              Please show this <%= I18n.t("mongoid.attributes.site_visit.code") %>: <%= self.code %> at the project site.
            </p>
          </div>
        </div>') if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "site_visit_rescheduled_to_channel_partner").blank?

      end
    end
  end
end
