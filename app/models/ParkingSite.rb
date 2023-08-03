class ParkingSite
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :total_spots, type: Integer

  has_many :spots
  has_many :tickets

  validates :name, presence: true, uniqueness: true
  validates :total_spots, presence: true, numericality: { greater_than: 0 }
end
