module CrmIntegration
  extend ActiveSupport::Concern

  included do
    embeds_many :third_party_references, as: :reference_model

    accepts_nested_attributes_for :third_party_references, reject_if: proc { |attributes| attributes['reference_id'].blank? }
  end

  def resource_name
  end

  def update_external_ids(ids, crm_id)
    tpr = self.third_party_references.where(crm_id: crm_id).first || self.third_party_references.build(crm_id: crm_id)
    tpr.assign_attributes(ids)
    tpr.save
  end

  module ClassMethods

    def reference_resource_exists?(crm_id, reference_id)
      where("third_party_references.crm_id": crm_id, "third_party_references.reference_id": reference_id).present?
    end

  end
end
