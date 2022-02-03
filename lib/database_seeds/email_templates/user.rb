module DatabaseSeeds
  module EmailTemplates
    module User
      def self.seed client_id
        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "User", name: "user_manager_changed", subject: '<%= I18n.t("users.role.#{manager.role}") %> for <%= I18n.t("global.user") %>: <%= name %> Updated', content: '<div class="card w-100">
          <div class="card-body">
            <p>Dear <%= name %>,</p>
            <p>
              <%= I18n.t("users.role.#{manager.role}") %> has been changed on <%= I18n.t("global.user") %> <strong><%= name %></strong>. New assigned <%= I18n.t("mongoid.attributes.user.manager_id") %> is <strong><%= manager.name %></strong>
            </p>
          </div>
        </div>') if ::Template::EmailTemplate.where(name: "user_manager_changed").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "User", name: "referral_invitation", subject: "Invitation", content: '<div class="card w-100">
          <div class="card-body">
            <p>Dear <%= name %>,</p>
            <p>
              I would like to invite you in <%= self.booking_portal_client.booking_portal_domains.join(", ") %>.
              Please click on the
               <%= ActionController::Base.helpers.link_to "link", Rails.application.routes.url_helpers.new_channel_partner_url(custom_referral_code: self.referred_by.referral_code) %> to register or use <span class="badge badge-info"> <%= self.referred_by.referral_code %> </span> code while sign up.
            </p>
            </br>
            </br>
            <p>
              Thanks & Regards </br>
              <%= self.referred_by.name %>
            </p>
          </div>
        </div>') if ::Template::EmailTemplate.where(name: "referral_invitation").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: Client.first.id, subject_class: "User", name: "user_confirmation_instructions", subject: "Confirmation Instructions", content: '<div class="card w-100">
            <div class="card-body">
              <p>
                Dear <%= self.name %>,
              </p>
              <div class="mb-3"></div>
              <p>
                <% if self.role?("channel_partner") %>
                  Thank you for registering as a Channel Partner at <%= current_project.name %>. Please confirm your account by clicking the link below. <br/>
                  You can start entering your leads as soon as your account is confirmed.
                <% elsif self.buyer? %>
                  <% if self.manager_id.present? && self.manager.role?("channel_partner") %>
                    Your interest for <%= current_project.name %> has been registered by <%= self.manager.name %>. Please confirm your account by clicking the link below and book your Home in 4 easy steps!<br/>
                  <% else %>
                    Thank you for registering at <%= current_project.name %>. Please confirm your account by clicking the link below and book your Home in 4 easy steps!
                  <% end %>
                <% else %>
                  Please confirm your account by clicking the link below.
                <% end %>
              </p>
              <div class="mb-3"></div>
              <a href=<%= self.confirmation_url %>>Confirm account</a>
            </div>
          </div>') if ::Template::EmailTemplate.where(name: "user_confirmation_instructions").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: Client.first.id, subject_class: "User", name: "account_confirmation", subject: "Account Confirmed", content: '<div class="card w-100">
            <div class="card-body">
              <p>
                Dear <%= self.name %>,
              </p>
              <div class="mb-3"></div>
              <p>
                <% if self.role?("channel_partner") %>
                  Thank you for registering as a Channel Partner at <%= current_project.name %>. Your account is confirmed. <br/>
                  You can start entering your leads.
                <% elsif self.buyer? %>
                  <% if self.manager_id.present? && self.manager.role?("channel_partner") %>
                    Your interest for <%= current_project.name %> has been registered by <%= self.manager.name %>. Your account is confirmed. <br/>
                  <% else %>
                    Thank you for registering at <%= current_project.name %>. Your account is confirmed.
                  <% end %>
                <% else %>
                  Your account is confirmed.
                <% end %>
              </p>
              <div class="mb-3"></div>
                <p>
                  Your credentials are as follows:
                    Email: <%= self.email %>
                    Password: <%= self.temporary_password %>
                </p>
            </div>
          </div>') if ::Template::EmailTemplate.where(name: "account_confirmation").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "User", name: "cp_user_register_in_company", subject: '<%= name %> has requested to register his account into your company on <%= I18n.t("global.brand") %>', content: '<div class="card w-100">
          <div class="card-body">
            <p>Dear <%= temp_channel_partner&.primary_user&.name || "Sir/Madam" %>,</p>
            <p>
              <%= name %> has requested to register his account into your company on <%= I18n.t("global.brand") %>.
              Please use the following link to approve his/her account to give him/her access as a <%= I18n.t("mongoid.attributes.user/role.channel_partner") %> into your company.
              <%= ActionController::Base.helpers.link_to "Approve or Reject #{I18n.t("mongoid.attributes.user/role.channel_partner")}", Rails.application.routes.url_helpers.add_user_account_channel_partners_url(register_code: self.register_in_cp_company_token, channel_partner_id: self.temp_channel_partner&.id.to_s) %>
            </p>
          </div>
        </div>') if ::Template::EmailTemplate.where(name: "cp_user_register_in_company").blank?
      end
    end
  end
end
