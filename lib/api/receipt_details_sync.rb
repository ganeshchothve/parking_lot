module Api
  class ReceiptDetailsSync < Api::Syncc
    Api::Syncc::DATA_FIELDS = %w[receipt_id total_amount status order_id payment_mode issued_date issuing_bank issuing_bank_branch payment_identifier tracking_id status_message payment_gateway processed_on comments gateway_response].freeze
    attr_accessor :url

    def initialize(client_api, record, _parent_sync_record = nil)
      super(client_api, record, parent_sync_record)
      raise ArgumentError, 'User associated with the receipt should have an erp-id' if receipt.user.erp_id.blank?
      @url = get_url
    end

    def name
      :receipt
    end

    def record_user
      record.user
    end

    private

    def set_request_payload
      super
      request_payload.store(:user_erp_id, record.user.erp_id)
      request_payload.store(:booking_detail_erp_id, record.booking_detail.erp_id) if record.booking_detail.present?
      request_payload.store(:project_unit_erp_id, record.project_unit.erp_id) if record.project_unit.present?
      request_payload.store(:creator_name, record.creator.name)
      request_payload
    end
  end
end
