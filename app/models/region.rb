class Region
  include Mongoid::Document
  include Mongoid::Timestamps
  include InsertionStringMethods
  include ArrayBlankRejectable

  field :city, type: String
  field :partner_regions, type: Array

  embedded_in :client

  validates :city, :partner_regions, presence: true
  validates :city, uniqueness: true

  def name_in_error
    city
  end
end
