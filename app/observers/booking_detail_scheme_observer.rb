class BookingDetailSchemeObserver < Mongoid::Observer
  def before_validation booking_detail_scheme
    booking_detail_scheme.send(booking_detail_scheme.event) if booking_detail_scheme.event.present?
     if booking_detail_scheme.derived_from_scheme_id_changed? && !booking_detail_scheme.created_by_user
      attributes = BookingDetailScheme.derived_scheme_attributes(booking_detail_scheme.derived_from_scheme_id)
      if booking_detail_scheme.payment_adjustments.present?
        attributes[:payment_adjustments_attributes] = [] if attributes[:payment_adjustments_attributes].blank?
        booking_detail_scheme.payment_adjustments.each{|adj| attributes[:payment_adjustments_attributes] << {_id: adj.id, _destroy: true}.with_indifferent_access}
      end
      booking_detail_scheme.assign_attributes(attributes)
    end
  end
   def before_save booking_detail_scheme
    if booking_detail_scheme.derived_from_scheme_id_changed?
      booking_detail_scheme.payment_schedule_template_id = booking_detail_scheme.derived_from_scheme.payment_schedule_template.id
      booking_detail_scheme.cost_sheet_template_id = booking_detail_scheme.derived_from_scheme.cost_sheet_template.id
    end
  end
   def after_save booking_detail_scheme
    if booking_detail_scheme.status_changed? && booking_detail_scheme.status == "approved"
      booking_detail_scheme.booking_detail.booking_detail_schemes.where(status: "approved", id: {"$ne" => booking_detail_scheme.id}).each do |scheme|
        scheme.event = "disabled"
        scheme.save
      end
      project_unit = booking_detail_scheme.booking_detail.project_unit
      project_unit.calculate_agreement_price
      project_unit.save
    end
    if booking_detail_scheme.status_changed?
      if booking_detail_scheme.status == "draft" && booking_detail_scheme.created_by_user
        SchemeMailer.send_draft booking_detail_scheme.id, booking_detail_scheme.created_by.id
      elsif booking_detail_scheme.status == "approved"
        SchemeMailer.send_approved booking_detail_scheme.id
      elsif booking_detail_scheme.status == "disabled"
        SchemeMailer.send_disabled booking_detail_scheme.id
      end
    end
  end
end
