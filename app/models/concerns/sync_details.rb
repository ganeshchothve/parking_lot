module SyncDetails
  extend ActiveSupport::Concern
  include ApplicationHelper
  included do
    after_create -> { new_details }
    after_update -> { update_details }
  end

  def self.included(receiver)
    receiver.extend(ClassMethods)
    receiver.send(:include, InstanceMethods)
  end

  module InstanceMethods
    def update_details
      if current_client.selldo_form_id.present? && current_client.selldo_client_id.present?
        sync_log = SyncLog.new
        @erp_models = ErpModel.where(resource_class: self.class, action_name: 'update', is_active: true)
        @erp_models.each do |erp|
          sync_log.sync(erp, self)
        end
      end
    end

    def new_details
      if current_client.selldo_form_id.present? && current_client.selldo_client_id.present?
        sync_log = SyncLog.new
        @erp_models = ErpModel.where(resource_class: self.class, action_name: 'create', is_active: true)
        @erp_models.each do |erp|
          sync_log.sync(erp, self)
        end
      end
    end
  end
end
