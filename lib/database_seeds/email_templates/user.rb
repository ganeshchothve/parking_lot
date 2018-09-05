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
      end
    end
  end
end
