module Kylas
  class UpdatePicklistValues < BaseService

    attr_reader :user, :changes, :options

    def initialize(user, changes, options = {})
      @user = user
      @changes = changes
      @options = options
    end

    def call
      return if user.blank?

      if (user.role.in?(%w(cp_owner channel_partner)) && user.user_status_in_company == 'active' && (changes.keys & %w(first_name last_name)).presence)
        client = user.booking_portal_client

        kylas_base = Crm::Base.where(domain: ENV_CONFIG.dig(:kylas, :base_url), booking_portal_client_id: client.id).first
        admin_user = kylas_base.user

        deal_custom_field_id = client.kylas_custom_fields.dig(:deal, :id)
        lead_custom_field_id = client.kylas_custom_fields.dig(:lead, :id)
        meeting_custom_field_id = client.kylas_custom_fields.dig(:meeting, :id)

        if deal_custom_field_id.present?
          Kylas::UpdateDealPicklist.new(admin_user, user).call
        end

        if lead_custom_field_id.present?
          Kylas::UpdateLeadPicklist.new(admin_user, user).call
        end

        if meeting_custom_field_id.present?
          Kylas::UpdateMeetingPicklist.new(admin_user, user).call
        end
      end
    end
  end
end
