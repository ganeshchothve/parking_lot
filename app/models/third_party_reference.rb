class ThirdPartyReference
  include Mongoid::Document
  include Mongoid::Timestamps

  field :domain, type: String
  field :reference_id, type: String

  embedded_in :reference, polymorphic: true

  validates_uniqueness_of :domain, scope: [:reference_id, :reference_type]

end