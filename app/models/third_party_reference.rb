class ThirdPartyReference
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  field :reference_id, type: String

  embedded_in :reference_model, polymorphic: true
  belongs_to :crm, class_name: 'Crm::Base'
  validates_uniqueness_of :crm_id, scope: :reference_model
  validate :reference_id_uniqueness

  def reference_id_uniqueness
    if self.reference_id.present? && reference_model.class.where("third_party_references.reference_id": self.reference_id).present?
      reference_model.errors.add :base, "Duplicate reference id"
    end
  end
end
