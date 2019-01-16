class Admin::ProjectUnitPolicy < ProjectUnitPolicy
  # def new? def print? def create? def update? def block? def update_co_applicants? def update_project_unit? def payment? def process_payment? def checkout? def send_under_negotiation? from ProjectUnitPolicy

  def index?
    current_client.enable_actual_inventory?(user) && !user.buyer?
  end

  def ds?
    current_client.enable_actual_inventory?(user)
  end

  def show?
    index?
  end

  def edit?
    _role_based_check(true)
  end

  def export?
    %w[superadmin admin sales_admin crm].include?(user.role) && current_client.enable_actual_inventory?(user)
  end

  def mis_report?
    export?
  end

  def hold?
    valid = record.user.confirmed? && record.user.kyc_ready? && current_client.enable_actual_inventory?(user)
    valid &&= (record.user.project_units.where(status: 'hold').blank? && record.user_based_status(record.user) == 'available')
    valid &&= record.user.unattached_blocking_receipt(record.blocking_amount).present? if user.role?('channel_partner')
    valid = (valid && record.user.allowed_bookings > record.user.booking_details.nin(status: %w[cancelled swapped]).count)
    valid = (valid && record.user.unused_user_kyc_ids(record.id).present?)
    _role_based_check(valid)
  end

  def update_scheme?
    make_available?
  end

  def permitted_attributes(_params = {})
    attributes = %w[crm admin superadmin].include?(user.role) ? %i[auto_release_on booking_price blocking_amount] : []
    attributes += (make_available? ? [:status] : [])
    attributes += %i[user_id selected_scheme_id] if record.user_id.blank? && record.user_based_status(user) == 'available'
    if %w[superadmin admin].include?(user.role) && ProjectUnit.booking_stages.exclude?(record.status) && record.status != 'hold'
      attributes += [:name, :agreement_price, :all_inclusive_price, :status, :available_for, :blocked_on, :auto_release_on, :held_on, :base_rate, :client_id, :developer_name, :project_name, :project_tower_name, :unit_configuration_name, :selldo_id, :erp_id, :floor_rise, :floor, :floor_order, :bedrooms, :bathrooms, :carpet, :saleable, :sub_type, :type, :unit_facing_direction, costs_attributes: CostPolicy.new(user, Cost.new).permitted_attributes, data_attributes: DatumPolicy.new(user, Cost.new).permitted_attributes]
    end
    attributes += [:primary_user_kyc_id, :selected_scheme_id, user_kyc_ids: []] if record.user_id.present?
    attributes.uniq
  end

  private

  def _role_based_check(valid)
    valid = (valid && record.user.referenced_manager_ids.include?(user.id)) if (ProjectUnit.booking_stages.include?(record.status) || record.status == 'hold') && user.role == 'channel_partner'
    valid = (valid && true) if %w[cp sales sales_admin cp_admin admin].include?(user.role)
    valid
  end
end