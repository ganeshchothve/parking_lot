module DatabaseSeeds
  module EmailTemplates
    module UserRequest
      def self.seed client_id
        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "UserRequest", name: "cancellation_request_created", subject: "Cancellation Requested for Unit: <%= self.project_unit.name %>", content: '<div class="card w-100">
          <div class="card-body">
            <p>Dear <%= self.user.name %>,</p>
            <p>
              A cancellation has been requested on your booking of <%= project_unit.name %> at <%= project_unit.project_name %>. Our CRM team is reviewing the request and will get in touch with you shortly.
            </p>
          </div>
        </div>') if ::Template::EmailTemplate.where(name: "cancellation_request_created").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "UserRequest", name: "cancellation_request_resolved", subject: "Cancellation Request for Unit: <%= self.project_unit.name %> Resolved", content: '<div class="card w-100">
          <div class="card-body">
            <p>Dear <%= self.user.name %>,</p>
            <p>
              We are sorry to see you go. <br/>
              Cancellation request on your booking of <%= project_unit.name%> at <%= project_unit.project_name%> has been processed and your amount will be refunded to you in a few days.<br/><br/>
              To book another unit visit <%= user.dashboard_url %>
            </p>
          </div>
        </div>') if ::Template::EmailTemplate.where(name: "cancellation_request_resolved").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "UserRequest", name: "cancellation_request_swapped", subject: "Swap request resolved for Unit: <%= self.project_unit.name %> with new unit <%= self.alternate_project_unit.name%>", content: '<%= self.project_unit.name %>') if ::Template::EmailTemplate.where(name: "cancellation_request_swapped").blank?
      end
    end
  end
end
