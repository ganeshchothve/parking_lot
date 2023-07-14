module CrmIntegration
  extend ActiveSupport::Concern

  included do
    # Attributes used in events pushed to Interakt
    attr_accessor :event_payload

    has_many :api_logs, as: :resource
    embeds_many :third_party_references, as: :reference_model, after_add: :update_references

    accepts_nested_attributes_for :third_party_references, reject_if: proc { |attributes| attributes['reference_id'].blank? }
  end

  def get_binding
    binding
  end

  def resource_name
  end

  def update_external_ids(ids, crm_id)
    tpr = self.third_party_references.where(crm_id: crm_id).first || self.third_party_references.build(crm_id: crm_id)
    tpr.assign_attributes(ids)
    tpr.save if self.persisted?
  end

  def update_references(tpr)
    tpr.update_references
  end

  def push_in_crm(crm_base, force_create=false)
    if crm_base.present?
      crm_id = self.third_party_references.where(crm_id: crm_base.id).first&.reference_id
      if crm_id.present? && !force_create
        api = Crm::Api::Put.where(booking_portal_client_id: self.booking_portal_client_id, resource_class: self.class.to_s, base_id: crm_base.id, is_active: true).first
      else
        api = Crm::Api::Post.where(booking_portal_client_id: self.booking_portal_client_id, resource_class: self.class.to_s, base_id: crm_base.id, is_active: true).first
      end

      if self.valid? && api.present?
        api.execute(self)
        api_log = ApiLog.where(booking_portal_client_id: self.booking_portal_client_id, resource_id: self.id).first
      end
    end
    [api, api_log]
  end

  # used safe navigation operator "&."
  def crm_reference_id(crm_base)
    crm_base = Crm::Base.where(domain: crm_base, booking_portal_client_id: self.booking_portal_client.id).first if crm_base.is_a?(String)
    third_party_references.where("crm_id": crm_base.id).first&.reference_id if crm_base.present?
  end


  module ClassMethods

    def reference_resource_exists?(crm_id, reference_id)
      all.where("third_party_references.crm_id": crm_id, "third_party_references.reference_id": reference_id).present?
    end

  end
end
