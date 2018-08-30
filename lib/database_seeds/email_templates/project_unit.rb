module DatabaseSeeds
  module EmailTemplates
    module ProjectUnit
      def self.seed client_id
        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "ProjectUnit", name: "project_unit_blocked", subject: "Unit No. <%= self.name %> has been blocked!", content: '<div class="card w-100">
          <div class="card-body">
            <p>Dear <%= self.user.name %>,</p>
            <p>
              Welcome to <%= current_project.name %>, <%= current_project.description %>.
            </p>
            <p>
              We are pleased to inform that you are among the esteemed circle of customers who have booked an apartment at <%= current_project.name %>
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
            This unit will remain blocked for you for the next <%= self.blocking_days %> days. Please complete your payment of remaining amount within this duration to confirm your unit. To make additional payment please click <a href=<%= Rails.application.routes.url_helpers.dashboard_url %> target="_blank">here</a>.
            <br/><br/>
            Your KYC details are incomplete, to complete your registration you can update them <a href="<%= Rails.application.routes.url_helpers.user_user_kycs_url %>">here</a>.<br/><br/>
            Welcome once again and do share with us your views and feedback.
          </div>
        </div>') if ::Template::EmailTemplate.where(name: "project_unit_blocked").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "ProjectUnit", name: "project_unit_booked_tentative", subject: "Unit <%= self.name %> booked tentative", content: '<div class="card w-100">
            <div class="card-body">
              <p>Dear <%= self.name %>,</p>
              <p>
                Thank you for the payment towards Unit - <%= self.name %> at <%= current_project.name %>.
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
              <% if self.auto_release_on.present? %>
              This unit will remain blocked for you until <%= I18n.l(self.auto_release_on) %>. Please complete your payment of remaining amount within this duration to confirm your unit. To make additional payment please click <a href="<%= Rails.application.routes.url_helpers.dashboard_url %>">here</a>.
              <% end %>
              <br/><br/>
              In case your KYC details are incomplete, you can update them <a href="<%= Rails.application.routes.url_helpers.user_user_kycs_url %>">here</a>.<br/><br/>
            </div>
          </div>') if ::Template::EmailTemplate.where(name: "project_unit_booked_tentative").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "ProjectUnit", name: "project_unit_booked_confirmed", subject: "Congratulations on booking your home!", content: '<div class="card w-100">
            <div class="card-body">
              <p>Dear <%= self.user.name %>,</p>
              Congratulations!<br/><br/>
              Welcome to the <%= current_project.name %>! You\'re now the proud owner of Unit - <%= self.name %>.<br/><br/>
              Our executives will be in touch regarding agreement formalities.
            </div>
          </div>
          <div class="mt-3"></div>
          ' + DatabaseSeeds::EmailTemplates.project_unit_overview + '
          <div class="mt-3"></div>
          ' + DatabaseSeeds::EmailTemplates.project_unit_cost_sheet + '
          <div class="mt-3"></div>
          ' + DatabaseSeeds::EmailTemplates.project_unit_payment_schedule) if ::Template::EmailTemplate.where(name: "project_unit_booked_confirmed").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "ProjectUnit", name: "project_unit_released", subject: "Test", content: '<div class="card w-100">
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
          ' + DatabaseSeeds::EmailTemplates.project_unit_payment_schedule) if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, name: "project_unit_released").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "ProjectUnit", name: "auto_release_on_extended", subject: "Unit <%= self.name %> has been released", content: '<div class="card w-100">
            <div class="card-body">
              <p>Dear <%= self.user.name %>,</p>
              Your Unit - <%= self.name %> has been released.<br/><br/>
              In case you need any assistance, please get in touch with our support team.
            </div>
          </div>
          <div class="mt-3"></div>
          ' + DatabaseSeeds::EmailTemplates.project_unit_overview + '
          <div class="mt-3"></div>
          ' + DatabaseSeeds::EmailTemplates.project_unit_cost_sheet + '
          <div class="mt-3"></div>
          ' + DatabaseSeeds::EmailTemplates.project_unit_payment_schedule) if ::Template::EmailTemplate.where(name: "auto_release_on_extended").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "ProjectUnit", name: "daily_reminder_for_booking_payment", subject: "Payment reminder for <%= self.name %>", content: '<%= self.name %>') if ::Template::EmailTemplate.where(name: "daily_reminder_for_booking_payment").blank?
      end
    end
  end
end
