module CrmIntegration
  extend ActiveSupport::Concern

  included do
    embeds_many :third_party_references, as: :reference
  end

  def resource_name
  end

  def update_reference_id(reference_id, crm_id)
    tpr = self.third_party_references.where(crm_id: crm_id).first
    if tpr.blank?
      tpr = self.third_party_references.build(reference_id: reference_id, crm_id: crm_id)
      tpr.save
    end
  end

end