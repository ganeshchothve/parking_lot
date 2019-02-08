module Api
  class UserDetailsSync < Api::Syncc
    def initialize(erp_model, record, parent_sync_record = nil)
      super(erp_model, record, parent_sync_record)
    end

    def record_user
      record
    end
  end
end
