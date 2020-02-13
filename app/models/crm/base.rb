class Crm::Base
  include Mongoid::Document
  include Mongoid::Timestamps

  field :domain, type: String
  field :name, type: String

  has_many :apis, dependent: :destroy
end
