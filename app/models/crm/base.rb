class Crm::Base
  include Mongoid::Document
  field :domain, type: String
  field :name, type: String
  field :path, type: String

  has_many :apis, dependent: :destroy, foreign_key: :crm_id
end
