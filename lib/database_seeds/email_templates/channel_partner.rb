module DatabaseSeeds
  module EmailTemplates
    module ChannelPartner
      def self.seed(client_id)
        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "ChannelPartner", name: "channel_partner_status_active", subject: "Account has been approved", content: '<div class="card w-100">You account has been approved.</div>') if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, name: "channel_partner_status_active").blank?
        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "ChannelPartner", name: "channel_partner_status_rejected", subject: "Account has been rejected", content: '<div class="card w-100">You account has been rejected for following reason - <%= self.status_change_reason %>.</div>') if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, name: "channel_partner_status_rejected").blank?

        Template::EmailTemplate.create!(
          booking_portal_client_id: client_id,
          subject_class: "ChannelPartner",
          name: "channel_partner_created",
          subject: "New channel partner registered on your website",
          content: <<-'CP_CREATED'
<div class="card w-100">
  <div class="card-body">
    <p>
      A new channel partner has registered on your website.
      <% if self.status != "active" %>
        Please login on to the portal to approve or reject the registration request.
      <% end %>
    </p>
  </div>
</div>
<div class="card mt-3">
  <div class="card-body">
    <h5 class="text-center"><strong><%= global_labels[:channel_partner] %> Details</strong></h5>
    <table class="table table-striped table-sm mt-3">
      <tbody>
        <tr>
          <td><%= I18n.t('mongoid.attributes.channel_partner.name') %></td>
          <td class="text-right"><%= self.name %></td>
        </tr>
        <tr>
          <td><%= I18n.t('mongoid.attributes.channel_partner.rera_id') %></td>
          <td class="text-right"><%= self.rera_id %></td>
        </tr>
        <tr>
          <td><%= I18n.t('mongoid.attributes.channel_partner.status') %></td>
          <td class="text-right"><%= ChannelPartner.human_attribute_name("status.#{self.status}") %></td>
        </tr>
        <tr>
          <td><%= I18n.t('mongoid.attributes.channel_partner.company_name') %></td>
          <td class="text-right"><%= self.company_name %></td>
        </tr>
        <tr>
          <td><%= I18n.t('mongoid.attributes.channel_partner.pan_number') %></td>
          <td class="text-right"><%= self.pan_number %></td>
        </tr>
        <tr>
          <td><%= I18n.t('mongoid.attributes.channel_partner.gstin_number') %></td>
          <td class="text-right"><%= self.gstin_number %></td>
        </tr>
        <tr>
          <td><%= I18n.t('mongoid.attributes.channel_partner.aadhaar') %></td>
          <td class="text-right"><%= self.aadhaar %></td>
        </tr>
        <% if self.address.present? %>
          <tr>
            <td><%= I18n.t('mongoid.attributes.channel_partner.address') %></td>
            <td class="text-right"><%= self.address.to_sentence %></td>
          </tr>
        <% end %>
      </tbody>
    </table>
  </div>
</div>
CP_CREATED
        ) if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, name: "channel_partner_created").blank?


        Template::EmailTemplate.create!(
          booking_portal_client_id: client_id,
          subject_class: "ChannelPartner",
          name: "channel_partner_updated",
          subject: "Channel partner details updated",
          content: <<-'CP_UPDATED'
<div class="card w-100">
  <div class="card-body">
    <p>
      <%= self.name %> channel partner has updated his details.
      Please find below updated details.
    </p>
  </div>
</div>
<div class="card mt-3">
  <div class="card-body">
    <h5 class="text-center"><strong><%= global_labels[:channel_partner] %> Details</strong></h5>
    <table class="table table-striped table-sm mt-3">
      <tbody>
        <tr>
          <td><%= I18n.t('mongoid.attributes.channel_partner.name') %></td>
          <td class="text-right"><%= self.name %></td>
        </tr>
        <tr>
          <td><%= I18n.t('mongoid.attributes.channel_partner.rera_id') %></td>
          <td class="text-right"><%= self.rera_id %></td>
        </tr>
        <tr>
          <td><%= I18n.t('mongoid.attributes.channel_partner.status') %></td>
          <td class="text-right"><%= ChannelPartner.human_attribute_name("status.#{self.status}") %></td>
        </tr>
        <tr>
          <td><%= I18n.t('mongoid.attributes.channel_partner.company_name') %></td>
          <td class="text-right"><%= self.company_name %></td>
        </tr>
        <tr>
          <td><%= I18n.t('mongoid.attributes.channel_partner.pan_number') %></td>
          <td class="text-right"><%= self.pan_number %></td>
        </tr>
        <tr>
          <td><%= I18n.t('mongoid.attributes.channel_partner.gstin_number') %></td>
          <td class="text-right"><%= self.gstin_number %></td>
        </tr>
        <tr>
          <td><%= I18n.t('mongoid.attributes.channel_partner.aadhaar') %></td>
          <td class="text-right"><%= self.aadhaar %></td>
        </tr>
        <% if self.address.present? %>
          <tr>
            <td><%= I18n.t('mongoid.attributes.channel_partner.address') %></td>
            <td class="text-right"><%= self.address.to_sentence %></td>
          </tr>
        <% end %>
      </tbody>
    </table>
  </div>
</div>
CP_UPDATED
        ) if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, name: "channel_partner_updated").blank?
      end
    end
  end
end
