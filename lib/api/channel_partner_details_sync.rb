module Api
  class ChannelPartnerDetailsSync < Api::Syncc
    def initialize(erp_model, record, parent_sync_record = nil)
      super(erp_model, record, parent_sync_record)
      execute
    end

    def record_user
      record
    end

    def update_user_details
      User.where(manager_id: record.id).each do |user|
        # e = ErpModel.new
        # e.action_name = "update"
        # e.http_verb = "post"
        # e.resource_class = "user"
        # e.domain = erp_model.domain
        # e.reference_key_location = erp_model.reference_key_location
        # e.reference_key_name = erp_model.reference_key_name
        # e.request_type = erp_model.request_type
        # e.url?
        current_user = Api::UserDetailsSync.new(erp_model, user)
      end
    end

    def execute
      super
      update_user_details
    end
  end
end
