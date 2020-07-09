class ThirdPartyReference
  include Mongoid::Document
  include Mongoid::Timestamps

  field :domain, type: String
  field :reference_id, type: String

  embedded_in :reference, polymorphic: true
  belongs_to :crm, class_name: 'Crm::Api::Post', optional: true
  validates_uniqueness_of :crm_id, scope: [:reference_id, :reference_type]

end