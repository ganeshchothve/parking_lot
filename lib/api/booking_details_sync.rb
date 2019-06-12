module Api
  class BookingDetailsSync < Api::Syncc
    def initialize(erp_model, record, parent_sync_record = nil)
      super(erp_model, record, parent_sync_record)
      raise ArgumentError, 'User associated with the booking should have an erp-id' if record.user.erp_id.blank?
    rescue ArgumentError => e
      e.message
    end

    def record_user
      record.user
    end
  end
end
