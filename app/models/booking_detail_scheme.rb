class BookingDetailScheme < Scheme

  field :derived_from_scheme_id, type: BSON::ObjectId

  belongs_to :booking_detail, optional: true

  def derived_scheme_attributes
    scheme = Scheme.find self.derived_from_scheme_id
    cloned_scheme = scheme.clone
    attributes = cloned_scheme.attributes.merge(booking_detail_id: self.booking_detail_id)
    attributes.delete "_type"
    attributes.delete "_id"
    if cloned_scheme.payment_adjustments.present?
      attributes[:payment_adjustments_attributes] = scheme.payment_adjustments.collect do |payment_adjustment|
        attrs = payment_adjustment.clone.attributes
        attrs.delete "_id"
        attrs
      end
    end
    attributes
  end
end
