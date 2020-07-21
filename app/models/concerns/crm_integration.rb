module CrmIntegration
  extend ActiveSupport::Concern

  included do
    embeds_many :third_party_references, as: :reference
  end

  def resource_name
  end

  def update_external_ids(ids, crm_id)
    tpr = self.third_party_references.where(crm_id: crm_id).first
    if tpr.blank?
      tpr = self.third_party_references.build(crm_id: crm_id)
      tpr.assign_attributes(ids)
      tpr.save
    else
      ids.delete(:reference_id)
      tpr.assign_attributes(ids)
      tpr.save
    end
  end

end