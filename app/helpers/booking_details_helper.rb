module BookingDetailsHelper

  def get_booking_detail_object(project_unit)
    if project_unit.status == 'blocked'
      project_unit.booking_detail
    else
      booking_detail = BookingDetail.new(project_unit: project_unit)
      scheme = project_unit.scheme
      booking_detail.booking_detail_schemes.build(
        derived_from_scheme_id: scheme.id,
        booking_portal_client_id: scheme.booking_portal_client_id,
        cost_sheet_template_id: scheme.cost_sheet_template_id,
        payment_schedule_template_id: scheme.payment_schedule_template_id,
        project_unit_id: project_unit.id,
        status: scheme.status
      )
      booking_detail
    end
  end
end
