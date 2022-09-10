module BookingDetailsHelper

  def custom_add_booking_path
    admin_booking_details_path('remote-state': new_admin_booking_detail_path)
  end

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
      booking_detail = BookingDetail.new(project_unit: project_unit, creator_id: current_user.id)
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

  def filter_booking_detail_options(booking_detail_id=nil)
    if booking_detail_id.present?
      BookingDetail.where(_id: booking_detail_id).map{|bd| [bd.ds_name, bd.id]}
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

  def filter_lead_options
    if params.dig(:fltrs, :lead_id).present?
      Lead.where(_id: params.dig(:fltrs, :lead_id)).map{|lead| [lead.ds_name(current_user), lead.id]}
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

  def filter_incentive_scheme_options
    if params.dig(:fltrs, :incentive_scheme_id).present?
      IncentiveScheme.where(_id: params.dig(:fltrs, :incentive_scheme_id)).map{|incentive_scheme| [incentive_scheme.name, incentive_scheme.id]}
    else
      []
    end
  end

  def available_booking_custom_templates(booking_detail)
    templates = ::Template::CustomTemplate.where(subject_class: 'BookingDetail', project_id: booking_detail.project.id, is_active: true).collect{|t| [t.name.titleize, t.id]}
    booking_form_and_allotment_letter_templates = Template.where(project_id: booking_detail.project.id, is_active: true).in(name: ['allotment_letter', 'booking_detail_form_html']).map{|t| [t.name.try(:titleize), t.id]}
    booking_form_and_allotment_letter_templates + templates
  end

  def allow_booking_approval_state_change?(booking_detail)
    policy([current_user_role_group, booking_detail]).move_to_next_approval_state? && policy([current_user_role_group, booking_detail]).editable_field?('approval_event')
  end

end
