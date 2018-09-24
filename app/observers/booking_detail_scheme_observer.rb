class BookingDetailSchemeObserver < Mongoid::Observer
  def before_save booking_detail_scheme
    if booking_detail_scheme.derived_from_scheme_id_changed?
      scheme = Scheme.find booking_detail_scheme.derived_from_scheme_id
      cloned_scheme = scheme.clone
      attributes = cloned_scheme.attributes.merge(booking_detail_id: booking_detail_scheme.booking_detail_id)
      attributes.delete "_type"
      booking_detail_scheme.payment_adjustments = []
      if cloned_scheme.payment_adjustments.present?
        booking_detail_scheme.payment_adjustments = cloned_scheme.payment_adjustments
      end
    end
  end
end
