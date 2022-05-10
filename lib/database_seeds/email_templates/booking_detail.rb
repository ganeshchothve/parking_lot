module DatabaseSeeds
  module EmailTemplates
    module BookingDetail
      def self.seed(project_id, client_id)
        Template::EmailTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "BookingDetail", name: "cost_sheet_and_payment_schedule", subject: "Cost sheet and Payment Schedule", content: '<div class="card w-100">PFA cost sheet and payment schedule</div>') if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "cost_sheet_and_payment_schedule").blank?
        Template::EmailTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "BookingDetail", name: "booking_blocked", subject: "Unit No. <%= self.name %> has been blocked!", content: '<div class="card w-100">
          <div class="card-body">
            <p>Dear <%= self.user.name %>,</p>
            <p>
              Welcome to <%= self.project.name %>, <%= self.project.description %>.
            </p>
            <p>
              We are pleased to inform that you are among the esteemed circle of customers who have booked an apartment at <%= self.project.name %>
            </p>
          </div>
        </div>
        <div class="mt-3"></div>
        ' + DatabaseSeeds::EmailTemplates.project_unit_overview + '
        <div class="mt-3"></div>
        ' + DatabaseSeeds::EmailTemplates.project_unit_cost_sheet + '
        <div class="mt-3"></div>
        ' + DatabaseSeeds::EmailTemplates.project_unit_payment_schedule + '
        <div class="mt-3"></div>
        <div class="card w-100">
          <div class="card-body">
            This unit will remain blocked for you for the next <%= current_client.blocking_days %> days. Please complete your payment of remaining amount within this duration to confirm your unit. To make additional payment please click <a href=<%= Rails.application.routes.url_helpers.dashboard_url %> target="_blank">here</a>.
            <br/><br/>
            Your KYC details are incomplete, to complete your registration you can update them <a href="<%= Rails.application.routes.url_helpers.buyer_user_kycs_url %>">here</a>.<br/><br/>
            Welcome once again and do share with us your views and feedback.
          </div>
        </div>') if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "booking_blocked").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "BookingDetail", name: "booking_tentative", subject: "Unit <%= self.name %> booked tentative", content: '<div class="card w-100">
            <div class="card-body">
              <p>Dear <%= self.name %>,</p>
              <p>
                Thank you for the payment towards Unit - <%= self.name %> at <%= self.project.name %>.
              </p>
            </div>
          </div>
          <div class="mt-3"></div>
          ' + DatabaseSeeds::EmailTemplates.project_unit_overview + '
          <div class="mt-3"></div>
        ' + DatabaseSeeds::EmailTemplates.project_unit_cost_sheet + '
          <div class="mt-3"></div>
        ' + DatabaseSeeds::EmailTemplates.project_unit_payment_schedule + '
          <div class="mt-3"></div>
          <div class="card">
            <div class="card-body">
              <% if self.project_unit.auto_release_on.present? %>
              This unit will remain blocked for you until <%= I18n.l(self.project_unit.auto_release_on) %>. Please complete your payment of remaining amount within this duration to confirm your unit. To make additional payment please click <a href="<%= Rails.application.routes.url_helpers.dashboard_url %>">here</a>.
              <% end %>
              <br/><br/>
              In case your KYC details are incomplete, you can update them <a href="<%= Rails.application.routes.url_helpers.buyer_user_kycs_url %>">here</a>.<br/><br/>
            </div>
          </div>') if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "booking_tentative").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "BookingDetail", name: "booking_confirmed", subject: "Congratulations on booking your home!", content: '<div class="card w-100">
            <div class="card-body">
              <p>Dear <%= self.user.name %>,</p>
              Congratulations!<br/><br/>
              Welcome to the <%= self.project.name %>! You\'re now the proud owner of Unit - <%= self.name %>.<br/><br/>
              Our executives will be in touch regarding agreement formalities.
            </div>
          </div>
          <div class="mt-3"></div>
          ' + DatabaseSeeds::EmailTemplates.project_unit_overview + '
          <div class="mt-3"></div>
          ' + DatabaseSeeds::EmailTemplates.project_unit_cost_sheet + '
          <div class="mt-3"></div>
          ' + DatabaseSeeds::EmailTemplates.project_unit_payment_schedule) if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "booking_confirmed").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "BookingDetail", name: "project_unit_released", subject: "Your Booking for Unit <%= self.name %> has been cancelled", content: '<div class="card w-100">
            <div class="card-body">
              Your Unit - <%= self.name %> has been released.<br/><br/>
              In case you need any assistance, please get in touch with our support team.
            </div>
          </div>
          <div class="mt-3"></div>
          ' + DatabaseSeeds::EmailTemplates.project_unit_overview + '
          <div class="mt-3"></div>
          ' + DatabaseSeeds::EmailTemplates.project_unit_cost_sheet + '
          <div class="mt-3"></div>
          ' + DatabaseSeeds::EmailTemplates.project_unit_payment_schedule) if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "project_unit_released").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "BookingDetail", name: "auto_release_on_extended", subject: "Auto release date for Unit <%= self.name %> has been extended", content: '<div class="card w-100">
            <div class="card-body">
              <p>Dear <%= self.user.name %>,</p>
              Auto release date for Unit <%= self.name %> has been extended. Please deposit the next installment before the auto_release date i.e. <%= self.project_unit.auto_release_on %> <br/><br/>
              In case you need any assistance, please get in touch with our support team.
            </div>
          </div>
          <div class="mt-3"></div>
          ' + DatabaseSeeds::EmailTemplates.project_unit_overview + '
          <div class="mt-3"></div>
          ' + DatabaseSeeds::EmailTemplates.project_unit_cost_sheet + '
          <div class="mt-3"></div>
          ' + DatabaseSeeds::EmailTemplates.project_unit_payment_schedule) if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "auto_release_on_extended").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "BookingDetail", name: "daily_reminder_for_booking_payment", subject: "Payment reminder for <%= self.name %>", content: '<div class="card w-100">
          <div class="card-body">
            <p>Dear <%= self.user.name %>,</p>
            <p>
              You have booked your spot among the privileged few in <%= name %> at <%= project_unit.project_name %>. <br/>
              Kindly pay the remaining balance to complete the booking process. The due date is <%= I18n.l(project_unit.auto_release_on) %>.
              <br/><br/>
              Visit
              <a href=<%= user.dashboard_url %> target="_blank"><%= user.dashboard_url %></a>.
            </p>
          </div>
        </div>') if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "daily_reminder_for_booking_payment").blank?
      end

      def self.client_based_seed(client_id)
        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "BookingDetail", name: "second_booking_notification", subject: "Second booking alert for same project", content: 'Alert - Channel Partner <%= self.manager.try(:name) %> has added more than 1 booking on same customer <%= self.lead.try(:name) %> for project <%= self.try(:project).try(:name) %> on BeyondWalls portal. Please cross verify with channel Partner / channel partner manager before approval.') if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, name: "second_booking_notification").blank?
      end
    end
  end
end
