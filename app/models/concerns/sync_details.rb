module SyncDetails
  extend ActiveSupport::Concern
  include ApplicationHelper
  included do

    has_many :sync_logs, as: :resource
    embeds_many :third_party_references, as: :reference

    after_create -> { new_details }
    after_update -> { update_details }
  end

  def self.included(receiver)
    receiver.extend(ClassMethods)
    receiver.send(:include, InstanceMethods)
  end

  module InstanceMethods

    def erp_models
      ErpModel.where(resource_class: self.class.to_s)
    end

    def update_details
      sync_log = SyncLog.new
      _erp_models = erp_models.where(action_name: 'update', is_active: true)
      _erp_models.each do |erp|
        sync_log.sync(erp, self)
      end
    end

    def new_details
      sync_log = SyncLog.new
      _erp_models = ErpModel.where(resource_class: self.class, action_name: 'create', is_active: true)
      _erp_models.each do |erp|
        sync_log.sync(erp, self)
      end
    end

    def update_erp_id(erp_id, domain)
      # set(erp_id: erp_id)
      tpr = self.third_party_references.where(domain: domain).first
      if tpr.blank?
        tpr = self.third_party_references.build(reference_id: erp_id, domain: domain)
        tpr.save
      end
    end

    def reference_id(erp_model)
      third_party_references.where(domain: erp_model.domain).distinct(:reference_id)[0]
    end
  end
end
