class ThirdPartyReference
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  field :reference_id, type: String

  embedded_in :reference_model, polymorphic: true
  belongs_to :crm, class_name: 'Crm::Base'
  validates_uniqueness_of :crm_id, scope: :reference_model
end
