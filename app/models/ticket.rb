class Ticket
  include Mongoid::Document
  include Mongoid::Timestamps

  TICKET_STATUSES = %w(active expired)

  field :status, type: String

  belongs_to :spot
  belongs_to :parking_site
  belongs_to :car

  validates :status, inclusion: { in: TICKET_STATUSES }

  accepts_nested_attributes_for :car

end
