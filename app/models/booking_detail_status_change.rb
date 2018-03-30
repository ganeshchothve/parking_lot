class BookingDetailStatusChange
  include Mongoid::Document

  field :status, type: String
  field :status_was, type: String
  field :changed_on, type: DateTime

  embedded_in :booking_detail
end
