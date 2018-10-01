class BookingDetailSchemeObserver < Mongoid::Observer
  def before_validation booking_detail_scheme
    if booking_detail_scheme.derived_from_scheme_id_changed?
      attributes = booking_detail_scheme.derived_scheme_attributes
      if booking_detail_scheme.payment_adjustments.present?
        attributes[:payment_adjustments_attributes] = [] if attributes[:payment_adjustments_attributes].blank?
        booking_detail_scheme.payment_adjustments.each{|adj| attributes[:payment_adjustments_attributes] << {_id: adj.id, _destroy: true}.with_indifferent_access}
      end
      booking_detail_scheme.assign_attributes(attributes)
    end
  end
end
