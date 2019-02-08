module Api
  class ChannelPartnerDetailsSync < Api::Syncc
    def initialize(erp_model, record, parent_sync_record = nil)
      super(erp_model, record, parent_sync_record)
    end

    def record_user
      record
    end

    def update_user_details
      erp = ErpModel.where(domain: erp_model.domain, action_name: 'update', resource_class: 'User', request_type: erp_model.request_type).first
      if erp.present?
        User.where(manager_id: record.id).each do |user|
          current_user = Api::UserDetailsSync.new(erp, user)
        end
      end
    end

    def execute
      super
      update_user_details
    end
  end
end
