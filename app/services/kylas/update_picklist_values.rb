module Kylas
  class UpdatePicklistValues < BaseService

    attr_reader :user, :changes, :options

    def initialize(user, changes, options = {})
      @user = user
      @changes = changes
      @options = options
    end

    def call
      return if user.blank? || options.blank?
  
      if (user.role.in?(%w(cp_owner channel_partner)) && user.user_status_in_company == 'active' && (changes.keys & %w(first_name last_name)).presence)
        client = user.booking_portal_client
        admin_user = client.users.admin.ne(kylas_access_token: nil).first

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