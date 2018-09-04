module DatabaseSeeds
  module EmailTemplates
    module UserRequest
      def self.seed client_id
        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "UserRequest::Cancellation", name: "cancellation_request_created", subject: "Cancellation Requested for Unit: <%= self.project_unit.name %>", content: '<div class="card w-100">
          <div class="card-body">
            <p>Dear <%= self.user.name %>,</p>
            <p>
              A cancellation has been requested on your booking of <%= project_unit.name %> at <%= project_unit.project_name %>. Our CRM team is reviewing the request and will get in touch with you shortly.
            </p>
          </div>
        </div>') if ::Template::EmailTemplate.where(name: "cancellation_request_created").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "UserRequest::Cancellation", name: "cancellation_request_resolved", subject: "Cancellation Request for Unit: <%= self.project_unit.name %> Resolved", content: '<div class="card w-100">
          <div class="card-body">
            <p>Dear <%= self.user.name %>,</p>
            <p>
              We are sorry to see you go. <br/>
              Cancellation request on your booking of <%= project_unit.name%> at <%= project_unit.project_name%> has been processed and your amount will be refunded to you in a few days.<br/><br/>
              To book another unit please click <a href="<%= user.dashboard_url %>">here</a>.
            </p>
          </div>
        </div>') if ::Template::EmailTemplate.where(name: "cancellation_request_resolved").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "UserRequest::Swap", name: "swap_request_created", subject: "Swap Requested for <%= I18n.t('globals.project_unit') %>: <%= self.project_unit.name %>", content: '<div class="card w-100">
          <div class="card-body">
            <p>Dear <%= self.user.name %>,</p>
            <p>
              A swap has been requested on your booking of <%= project_unit.name %> at <%= project_unit.project_name %>. Our CRM team is reviewing the request and will get in touch with you shortly.
            </p>
          </div>
        </div>') if ::Template::EmailTemplate.where(name: "swap_request_created").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "UserRequest::Swap", name: "swap_request_resolved", subject: "Swap Request for <%= I18n.t('globals.project_unit') %>: <%= self.project_unit.name %> Resolved", content: '<div class="card w-100">
          <div class="card-body">
            <p>Dear <%= self.user.name %>,</p>
            <p>
              Your Swap request on booking of <%= project_unit.name %> at <%= project_unit.project_name %> has been processed. We have blocked your requested <%= I18n.t("globals.project_unit") %>: <%= alternate_project_unit.name %> <br/><br/>
              To view your dashboard click <a href="<%= user.dashboard_url %>">here</a>.
            </p>
          </div>
        </div>') if ::Template::EmailTemplate.where(name: "swap_request_resolved").blank?
      end
    end
  end
end
