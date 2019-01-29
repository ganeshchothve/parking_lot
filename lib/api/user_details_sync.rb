module Api
  class UserDetailsSync < Api::Syncc
    Api::Syncc::DATA_FIELDS = %w[lead_id first_name last_name email phone utm_params manager_change_reason mixpanel_id time_zone confirmed_at created_at is_active].freeze
    attr_accessor :url

    def initialize(client_api, record, _parent_sync_record = nil)
      super(client_api, record, parent_sync_record)
      @url = get_url
    end

    def name
      :user
    end

    def record_user
      record
    end

    private

    def set_request_payload
      super
      request_payload.store(:confirmed, record.confirmed_at.present?)
      request_payload.store(:manager_erp_id, record.manager.erp_id) if record.manager.present? && record.manager.erp_id.present?
      request_payload.store(:manager_name, record.manager.name) if record.manager.present?
      request_payload.store(:portal_stage, record.portal_stages.order_by(:updated_at.desc).first) if record.portal_stages.present?
      request_payload
    end
  end
end
