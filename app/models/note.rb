class Note
  include Mongoid::Document
  include Mongoid::Timestamps
  extend DocumentsConcern

  # Add different types of documents which are uploaded on note.
  DOCUMENT_TYPES = []

  field :note, type: String
  field :note_type, type: String, default: :internal

  belongs_to :booking_portal_client, class_name: 'Client'
  belongs_to :notable, polymorphic: true
  has_many :assets, as: :assetable
  belongs_to :creator, class_name: 'User', optional: true # When system generates a note, creator is kept blank as it is not a user object

  default_scope -> { desc(:created_at) }

  validates :note, presence: true

  def self.available_note_types
    [
      { id: 'internal', text: 'Internal' },
      { id: 'user', text: 'Customer' }
    ]
  end
end
