class Note
  include Mongoid::Document
  include Mongoid::Timestamps

  field :note, type: String

  belongs_to :notable, polymorphic: true
  has_many :assets, as: :assetable

  validates :note, presence: true
end
