class Tier
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name, type: String
  has_many :channel_partners, class_name: 'User'
  has_many :incentive_schemes

  validates :name, uniqueness: true
end
