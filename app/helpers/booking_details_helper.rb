module BookingDetailsHelper

  def searches_bedrooms_names(data)
    if (current_user.role?('channel_partner') || current_user.manager_role?('channel_partner') )
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

  def filter_booking_detail_options(booking_detail_id)
    if booking_detail_id.present?
      BookingDetail.where(_id: booking_detail_id).map{|bd| [bd.name, bd.id]}
    else
      []
    end
  end

  def filter_project_tower_options
    if params.dig(:fltrs, :project_tower_id).present?
      ProjectTower.where(_id: params.dig(:fltrs, :project_tower_id)).map{|pt| [pt.name, pt.id]}
    else
      []
    end
  end

  def filter_user_options
    if params.dig(:fltrs, :user_id).present?
      User.in(role: User::BUYER_ROLES).where(_id: params.dig(:fltrs, :user_id)).map{|user| [user.ds_name, user.id]}
    else
      []
    end
  end

  def filter_manager_options
    if params.dig(:fltrs, :manager_id).present?
      User.nin(role: User::BUYER_ROLES).where(_id: params.dig(:fltrs, :manager_id)).map{|user| [user.ds_name, user.id]}
    else
      []
    end
  end
end
