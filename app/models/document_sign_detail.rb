class DocumentSignDetail
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  field :status, type: String

  belongs_to :asset
  belongs_to :document_sign
end
