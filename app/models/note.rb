class Note
  include Mongoid::Document
  include Mongoid::Timestamps

  field :note, type: String

  belongs_to :notable, polymorphic: true
  has_many :assets, as: :assetable
  belongs_to :creator, class_name: 'User'

  default_scope -> {desc(:created_at)}
  
  validates :note, presence: true
end
