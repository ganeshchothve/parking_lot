class DocumentSignDetail
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  field :status, type: String
  field :document_id, type: String
  field :request_id, type: String
  field :action_id, type: String

  belongs_to :asset
  belongs_to :document_sign
end
