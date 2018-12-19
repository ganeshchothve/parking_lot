=begin
class ProjectUnitPolicy < ApplicationPolicy
  #def new? def index? def permitted_attributes from ApplicationPolicy 

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
    current_client.enable_actual_inventory?(user)
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

  def create?
    false
  end

  def block?
    valid = ['hold'].include?(record.status) && record.user.confirmed? && record.user.kyc_ready? && current_client.enable_actual_inventory?(user)
    valid = (valid && record.user.allowed_bookings > record.user.booking_details.ne(status: "cancelled").count)
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
    valid = record.user_id.present? && (record.user_based_status(record.user) == "booked") && record.user.confirmed? && record.user.kyc_ready? && current_client.enable_actual_inventory?(user)
    _role_based_check(valid)
  end

  def send_under_negotiation?
    checkout?
  end
end
=end

class ProjectUnitPolicy < ApplicationPolicy
  #def new? from ApplicationPolicy 
  
  def index? #admin
    current_client.enable_actual_inventory?(user) && !user.buyer?
  end

  def ds? #admin
    current_client.enable_actual_inventory?(user)
  end

  def show? #admin
    index?
  end

  def print? #admin
    index?
  end

  def edit? #both
    valid = true
    valid = (record.status != "hold") if user.buyer? #buyer
    _role_based_check(valid)
  end

  def export? #admin
    ['superadmin', 'admin', 'sales_admin', 'crm'].include?(user.role) && current_client.enable_actual_inventory?(user)
  end

  def mis_report? #admin
    export?
  end

  def update? #both
    edit?
  end

  def create? #both
    false
  end

  def hold?#both
    valid = record.user.confirmed? && record.user.kyc_ready? && current_client.enable_actual_inventory?(user)
    valid = valid && (record.user.project_units.where(status: "hold").blank? && record.user_based_status(record.user) == 'available')
    valid = valid && record.user.unattached_blocking_receipt(record.blocking_amount).present? if user.role?('channel_partner') #admin
    valid = (valid && record.user.allowed_bookings > record.user.booking_details.nin(status: ["cancelled", "swapped"]).count)
    valid = (valid && record.user.unused_user_kyc_ids(record.id).present?)
    _role_based_check(valid)
  end

  def block?#both
    valid = ['hold'].include?(record.status) && record.user.confirmed? && record.user.kyc_ready? && current_client.enable_actual_inventory?(user)
    valid = (valid && record.user.allowed_bookings > record.user.booking_details.ne(status: "cancelled").count)
    _role_based_check(valid)
  end

  def make_available?#both
    valid = (record.status == 'hold' && current_client.enable_actual_inventory?(user))
    _role_based_check(valid)
  end

  def update_scheme? #admin
    make_available?
  end

  def update_co_applicants?#both
    valid = (ProjectUnit.booking_stages.include?(record.status) && current_client.enable_actual_inventory?(user))
    _role_based_check(valid)
  end

  def update_project_unit?#both
    valid = record.user.confirmed? && record.user.kyc_ready? && current_client.enable_actual_inventory?(user)
    _role_based_check(valid)
  end

  def payment?#both
    checkout? && record.user.confirmed? && record.user.kyc_ready? && current_client.enable_actual_inventory?(user)
  end

  def process_payment?#both
    checkout? && record.user.confirmed? && record.user.kyc_ready? && current_client.enable_actual_inventory?(user)
  end

  def checkout?#both
    valid = record.user_id.present? && (record.user_based_status(record.user) == "booked") && record.user.confirmed? && record.user.kyc_ready? && current_client.enable_actual_inventory?(user)
    _role_based_check(valid)
  end

  def permitted_attributes params={}
    attributes = ["crm", "admin", "superadmin"].include?(user.role) ? [:auto_release_on, :booking_price, :blocking_amount] : [] #admin
    attributes += (make_available? ? [:status] : [])
    attributes += [:user_id, :selected_scheme_id] if record.user_id.blank? && record.user_based_status(user) == 'available'

    if ['superadmin', 'admin'].include?(user.role) && ProjectUnit.booking_stages.exclude?(record.status) && record.status != 'hold' #admin
      attributes += [:name, :agreement_price, :all_inclusive_price, :status, :available_for, :blocked_on, :auto_release_on, :held_on, :base_rate, :client_id, :developer_name, :project_name, :project_tower_name, :unit_configuration_name, :selldo_id, :erp_id, :floor_rise, :floor, :floor_order, :bedrooms, :bathrooms, :carpet, :saleable, :sub_type, :type, :unit_facing_direction, costs_attributes: CostPolicy.new(user, Cost.new).permitted_attributes, data_attributes: DatumPolicy.new(user, Cost.new).permitted_attributes]
    end

    attributes += [:primary_user_kyc_id, :selected_scheme_id, user_kyc_ids: []] if record.user_id.present?

    attributes.uniq
  end

  def send_under_negotiation?#both
    checkout?
  end

  private
  def _role_based_check(valid) #split
    valid = (valid && (record.user_id == user.id)) if user.buyer? #buyer
    valid = (valid && (record.user.referenced_manager_ids.include?(user.id))) if (ProjectUnit.booking_stages.include?(record.status) || record.status == "hold") && user.role == "channel_partner" #admin
    valid = (valid && true) if ['cp', 'sales', 'sales_admin', 'cp_admin', 'admin'].include?(user.role) #admin
    valid
  end
end
