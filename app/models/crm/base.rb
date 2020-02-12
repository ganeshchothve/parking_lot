class Crm::Base
  include Mongoid::Document
  field :domain, type: String
  field :name, type: String

  has_many :apis, dependent: :destroy
end
