class BookingDetailScheme < Scheme

  field :derived_from_scheme_id, type: BSON::ObjectId

  belongs_to :booking_detail, optional: true
end
