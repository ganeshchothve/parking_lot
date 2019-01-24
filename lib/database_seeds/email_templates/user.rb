module DatabaseSeeds
  module EmailTemplates
    module User
      def self.seed client_id
        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "User", name: "user_manager_changed", subject: "<%= User.available_roles(booking_portal_client).find{|x| x[:id] == manager.role}[:text] %> for <%= I18n.t('global.user') %>: <%= name %> Updated", content: '<div class="card w-100">
          <div class="card-body">
            <p>Dear <%= name %>,</p>
            <p>
              <%= User.available_roles(booking_portal_client).find{|x| x[:id] == manager.role}[:text] %> has been changed on <%= I18n.t("global.user") %> <strong><%= name %></strong>. New assigned <%= I18n.t("mongoid.attributes.user.manager_id") %> is <strong><%= manager.name %></strong>
            </p>
          </div>
        </div>') if ::Template::EmailTemplate.where(name: "user_manager_changed").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "User", name: "referral_invitation", subject: "Invitation", content: '<div class="card w-100">
          <div class="card-body">
            <p>Dear <%= name %>,</p>
            <p>
              I would like to invite you in <%= self.booking_portal_client.booking_portal_domains.join(", ") %>.
              Please click on the
               <%= ActionController::Base.helpers.link_to "link", Rails.application.routes.url_helpers.register_url(custom_referral_code: self.referred_by.referral_code) %> to registror or use <span class="badge badge-info"> <%= self.referred_by.referral_code %> </span> code while sign up.
            </p>
            </br>
            </br>
            <p>
              Thanks & Regards </br>
              <%= self.referred_by.name %>
            </p>
          </div>
        </div>') if ::Template::EmailTemplate.where(name: "referral_invitation").blank?
      end
    end
  end
end
