class Region
  include Mongoid::Document
  include Mongoid::Timestamps
  include InsertionStringMethods

  field :city, type: String
  field :partner_regions, type: Array

  embedded_in :client

  validates :city, uniqueness: true
end
