class Note
  include Mongoid::Document
  include Mongoid::Timestamps
  include CrmIntegration
  extend DocumentsConcern

  # Add different types of documents which are uploaded on note.
  DOCUMENT_TYPES = []

  field :note, type: String
  field :note_type, type: String, default: :internal

  #kylas specific fields
  field :kylas_note_id, type: String

  belongs_to :booking_portal_client, class_name: 'Client'
  belongs_to :notable, polymorphic: true
  has_many :assets, as: :assetable
  belongs_to :creator, class_name: 'User', optional: true # When system generates a note, creator is kept blank as it is not a user object

  default_scope -> { desc(:created_at) }

  validates :note, presence: true

  scope :filter_by_creator_id, ->(creator_id) { where(creator_id: creator_id) }

  def self.available_note_types
    [
      { id: 'internal', text: 'Internal' },
      { id: 'user', text: 'Customer' }
    ]
  end

  def self.user_based_scope user, params
    custom_scope = {}
    if user.role.in?(%w(superadmin))
      custom_scope = { }
    elsif user.role?(:channel_partner)
      custom_scope = { creator_id: user.id }
    end

    custom_scope.merge!({booking_portal_client_id: user.booking_portal_client.id})
    custom_scope
  end
end
