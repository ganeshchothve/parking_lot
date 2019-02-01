module Api
  class UserKycDetailsSync < Api::Syncc
    def initialize(erp_model, record, parent_sync_record = nil)
      super(erp_model, record, parent_sync_record)
      raise ArgumentError, 'User associated with the KYC should be a buyer and have an erp-id' unless user_kyc.user.buyer? && user_kyc.user.erp_id.present? # call only if user buyer, raise exception if user_kyc.user.erp_id absent

      execute
    end

    def record_user
      record.user
    end
  end
end
