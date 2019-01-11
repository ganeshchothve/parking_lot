class ProjectUnitPolicy < ApplicationPolicy
  # def new? def index? def permitted_attributes from ApplicationPolicy

  def ds?
    false
  end

  def show?
    index?
  end

  def edit?
    false
  end

  def print?
    show?
  end

  def export?
    false
  end

  def mis_report?
    export?
  end

  def update?
    edit?
  end

  def hold?
    false
  end

  def create?
    false
  end
  
  def block?
    valid = ['hold'].include?(record.status) && record.user.confirmed? && record.user.kyc_ready? && current_client.enable_actual_inventory?(user)
    valid = (valid && record.user.allowed_bookings > record.user.booking_details.ne(status: 'cancelled').count)
    _role_based_check(valid)
  end

  def make_available?
    valid = (record.status == 'hold' && current_client.enable_actual_inventory?(user))
    _role_based_check(valid)
  end

  def update_scheme?
    false
  end

  def update_co_applicants?
    valid = (ProjectUnit.booking_stages.include?(record.status) && current_client.enable_actual_inventory?(user))
    _role_based_check(valid)
  end

  def update_project_unit?
    valid = record.user.confirmed? && record.user.kyc_ready? && current_client.enable_actual_inventory?(user)
    _role_based_check(valid)
  end

  def payment?
    checkout? && record.user.confirmed? && record.user.kyc_ready? && current_client.enable_actual_inventory?(user)
  end

  def process_payment?
    checkout? && record.user.confirmed? && record.user.kyc_ready? && current_client.enable_actual_inventory?(user)
  end

  def checkout?
    valid = record.user_id.present? && (record.user_based_status(record.user) == 'booked') && record.user.confirmed? && record.user.kyc_ready? && current_client.enable_actual_inventory?(user)
    _role_based_check(valid)
  end

  def send_under_negotiation?
    checkout?
  end

  def _role_based_check(valid)
    false
  end
  def permitted_attributes
    attributes = %w[crm admin superadmin].include?(user.role) ? %i[auto_release_on booking_price blocking_amount] : []
    attributes += (make_available? ? [:status] : [])
    attributes += %i[user_id selected_scheme_id] if record.user_id.blank? && record.user_based_status(user) == 'available'
    if %w[superadmin admin].include?(user.role) && ProjectUnit.booking_stages.exclude?(record.status) && record.status != 'hold'
      attributes += [:name, :agreement_price, :all_inclusive_price, :status, :available_for, :blocked_on, :auto_release_on, :held_on, :base_rate, :client_id, :developer_name, :project_name, :project_tower_name, :unit_configuration_name, :selldo_id, :erp_id, :floor_rise, :floor, :floor_order, :bedrooms, :bathrooms, :carpet, :saleable, :sub_type, :type, :unit_facing_direction, costs_attributes: CostPolicy.new(user, Cost.new).permitted_attributes, data_attributes: DatumPolicy.new(user, Cost.new).permitted_attributes]
    end
    attributes += [:primary_user_kyc_id, :selected_scheme_id, user_kyc_ids: []] if record.user_id.present?
    attributes
  end
end
