module Api
  class ReceiptDetailsSync < Api::Syncc
    def initialize(erp_model, record, parent_sync_record = nil)
      super(erp_model, record, parent_sync_record)
      raise ArgumentError, 'User associated with the receipt should have an erp-id' if receipt.user.erp_id.blank?

      execute
    end

    def record_user
      record.user
    end
  end
end
