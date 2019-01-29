module Api
  class BookingDetailsSync Api::Syncc
    Api::Syncc::DATA_FIELDS = %w[status]

    def initialize(client_api, record, parent_sync_record = nil)
      super(client_api, record, parent_sync_record)
      raise ArgumentError, 'User associated with the booking should have an erp-id' if booking_detail.user.erp_id.blank?
      @url = get_url
    end

    def name
      :booking_detail
    end

    def record_user
      record.user
    end

    private

    def set_request_payload
      super
      request_payload.store(:user_erp_id, record.user.erp_id) if record.user.present?
      request_payload.store(:project_unit_erp_id, record.project_unit.erp_id) if record.project_unit.present?
      request_payload.store(:primary_user_kyc_erp_id, record.primary_user_kyc.erp_id) if record.primary_user_kyc.erp_id
      request_payload.store(:manager_erp_id, record.manager.erp_id) if record.manager.present?
      request_payload.store(:primary_user_kyc_erp_id, record.primary_user_kyc.erp_id) if record.primary_user_kyc.erp_id
      request_payload.store(:receipts, record.receipts) if record.receipts.present?
      request_payload.store(:user_kycs, record.receipts) if record.receipts.present?
      request_payload
    end
  end
end
