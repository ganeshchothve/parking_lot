module Api
  class UserKycDetailsSync < Api::Syncc
    Api::Syncc::DATA_FIELDS = %w[salutation first_name last_name email phone dob pan_number aadhaar anniversary education_qualification designation customer_company_name configurations number_of_units preferred_floors min_budget max_budget comments nri oci poa poa_details poa_details_phone_no is_company gstn company_name existing_customer existing_customer_name existing_customer_project].freeze
    attr_accessor :url

    def initialize(client_api, record, _parent_sync_record = nil)
      super(client_api, record, parent_sync_record)
      raise ArgumentError, 'User associated with the KYC should be a buyer and have an erp-id' unless user_kyc.user.buyer? && user_kyc.user.erp_id.present? # call only if user buyer, raise exception if user_kyc.user.erp_id absent
      @url = get_url
    end

    def name
      :user_kyc
    end

    def record_user
      record.user
    end

    private

    def set_request_payload
      super
      request_payload.store(:user_erp_id, record.user.erp_id)
      request_payload
    end
  end
end
