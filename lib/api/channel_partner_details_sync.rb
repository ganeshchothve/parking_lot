module Api
  class ChannelPartnerDetailsSync < Api::Syncc
    Api::Syncc::DATA_FIELDS = %w[receipt_id total_amount status order_id payment_mode issued_date issuing_bank issuing_bank_branch payment_identifier tracking_id status_message payment_gateway processed_on comments gateway_response].freeze
    attr_accessor :url

    def initialize(client_api, record, _parent_sync_record = nil)
      super(client_api, record, parent_sync_record)
      @url = get_url
    end

    def record_user
      record
    end

    def update_user_details
      User.where(manager_id: record.id).each do |user|
        current_user = UserDetailsSync.new(client_api, user)
        current_user.on_update
      end
    end

    def on_create
      super
      update_user_details
    end

    def on_update
      super
      update_user_details
    end

    def name
      :channel_partner
    end

    private

    def set_params
      super
      request_payload.store(:addresses, record.addresses) if record.addresses.present?
      request_payload.store(:bank_details, record.bank_details) if record.bank_details.present?
      request_payload
    end
  end
end
