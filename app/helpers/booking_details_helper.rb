module BookingDetailsHelper

  def searches_bedrooms_names(data)
    if (current_user.role?('channel_partner') || ( current_user.manager && current_user.manager.role?('channel_partner') ))
      data.collect{|d| ["#{d.dig('_id', 'bedrooms')} BHK", d.dig('_id', 'bedrooms')]}
    else
      data.collect{|d| [ "#{d.dig('_id', 'bedrooms')} BHK starting at #{number_to_indian_currency(d.dig('min_agreement_price') ) }".html_safe, d.dig('_id', 'bedrooms') ]}
    end
  end

  def get_booking_detail_object(project_unit)
    if %w(blocked hold).include?(project_unit.status)
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
