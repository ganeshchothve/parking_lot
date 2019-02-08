module Api
  class BookingDetailsSync < Api::Syncc
    def initialize(erp_model, record, parent_sync_record = nil)
      super(erp_model, record, parent_sync_record)
      raise ArgumentError, 'User associated with the booking should have an erp-id' if booking_detail.user.erp_id.blank?
    end

    def record_user
      record.user
    end
  end
end
