module DatabaseSeeds
  module EmailTemplates
    module UserRequest
      def self.seed client_id
        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "UserRequest::Cancellation", name: "cancellation_request_pending", subject: "Cancellation Requested for Unit: <%= self.requestable.name %>", content: '<div class="card w-100">
          <div class="card-body">
            <p>Dear <%= self.user.name %>,</p>
            <% if requestable.kind_of?(BookingDetail) %>
              <p>
                A cancellation has been requested on your booking of <%= project_unit.name %> at <%= project_unit.project_name %>. Our CRM team is reviewing the request and will get in touch with you shortly.
              </p>
            <% elsif requestable.kind_of?(Receipt) %>
              <p>
                A cancellation has been requested on your booking of <%= requestable.name %>. Our CRM team is reviewing the request and will get in touch with you shortly.
              </p>
            <% end %>
          </div>
        </div>') if ::Template::EmailTemplate.where(name: "cancellation_request_pending").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "UserRequest::Cancellation", name: "cancellation_request_resolved", subject: "Cancellation Request for Unit: <%= self.project_unit.name %> Resolved", content: '<div class="card w-100">
          <div class="card-body">
            <p>Dear <%= self.user.name %>,</p>
            <% if requestable.kind_of?(BookingDetail) %>
              <p>
                We are sorry to see you go. <br/>
                Cancellation request on your booking of <%= project_unit.name%> at <%= project_unit.project_name%> has been processed and your amount will be refunded to you in a few days.<br/><br/>
                To book another unit please click <a href="<%= user.dashboard_url %>">here</a>.
              </p>
            <% elsif requestable.kind_of?(Receipt) %>
              <p>
                Cancellation request on your payment of <%= requestable.name%>  has been processed and your amount will be refunded to you in a few days.<br/>
              </p>
            <% end %>
          </div>
        </div>') if ::Template::EmailTemplate.where(name: "cancellation_request_resolved").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "UserRequest::Cancellation", name: "cancellation_request_rejected", subject: "Cancellation Request for Unit: <%= self.project_unit.name %> rejected", content: '<div class="card w-100">
          <div class="card-body">
            <p>Dear <%= self.user.name %>,</p>
            <% if requestable.kind_of?(BookingDetail) %>
              <p>
                Cancellation request on your booking of <%= project_unit.name%> at <%= project_unit.project_name%> has been rejected
              </p>
            <% elsif requestable.kind_of?(Receipt) %>
              <p>
                Cancellation request on your booking of <%= requestable.name%> has been rejected
              </p>
            <% end %>
          </div>
        </div>') if ::Template::EmailTemplate.where(name: "cancellation_request_rejected").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "UserRequest::Swap", name: "swap_request_pending", subject: "Swap Requested for <%= I18n.t('global.project_unit') %>: <%= self.project_unit.name %>", content: '<div class="card w-100">
          <div class="card-body">
            <p>Dear <%= self.user.name %>,</p>
            <% if self.requestable.kind_of?(BookingDetail) %>
              <p>
                A swap has been requested on your booking of <%= project_unit.name %> at <%= project_unit.project_name %>. Our CRM team is reviewing the request and will get in touch with you shortly.
              </p>
            <% elsif self.requestable.kind_of?(Receipt) %>
            <% end %>
          </div>
        </div>') if ::Template::EmailTemplate.where(name: "swap_request_pending").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "UserRequest::Swap", name: "swap_request_resolved", subject: "Swap Request for <%= I18n.t('global.project_unit') %>: <%= self.project_unit.name %> Resolved", content: '<div class="card w-100">
          <div class="card-body">
            <p>Dear <%= self.user.name %>,</p>
            <p>
              Your Swap request on booking of <%= project_unit.name %> at <%= project_unit.project_name %> has been processed. We have blocked your requested <%= I18n.t("global.project_unit") %>: <%= alternate_project_unit.name %> <br/><br/>
              To view your dashboard click <a href="<%= user.dashboard_url %>">here</a>.
            </p>
          </div>
        </div>') if ::Template::EmailTemplate.where(name: "swap_request_resolved").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "UserRequest::Swap", name: "swap_request_rejected", subject: "Swap Request for <%= I18n.t('global.project_unit') %>: <%= self.project_unit.name %> Rejected", content: '<div class="card w-100">
          <div class="card-body">
            <p>Dear <%= self.user.name %>,</p>
            <p>
              Your Swap request on booking of <%= project_unit.name %> at <%= project_unit.project_name %> has been rejected.
            </p>
          </div>
        </div>') if ::Template::EmailTemplate.where(name: "swap_request_rejected").blank?
      end
    end
  end
end
