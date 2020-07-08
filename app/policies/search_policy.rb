class SearchPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    valid = true
    if record.project_unit.present? && record.project_unit.status == 'hold'
      if record.user_id != record.project_unit.booking_details.hold.first.user_id
        valid = false
      end
    end
    valid
  end

  def tower?
    index?
  end

  def new?
    valid = true
    valid = valid && (record.user_id == user.id) if user.buyer?
    valid = valid && record.user.referenced_manager_ids.include?(user.id) if user.role == "channel_partner"
    valid = valid && true if ['cp', 'sales', 'admin'].include?(user.role)
    valid
  end

  def three_d?
    current_client.external_inventory_view_config.present? && current_client.external_inventory_view_config.enabled? && new?
  end

  def edit?
    new?
  end

  def export?
    ['admin'].include?(user.role)
  end

  def create?
    new?
  end

  def update?
    edit?
  end

  def checkout?
    new?
  end

  def hold?
    new?
  end

  def payment?
    new?
  end

  def gateway_payment?
    new?
  end

  def make_available?
    record.project_unit_id.present? && "#{current_user_role_group}::ProjectUnitPolicy".constantize.new(user, record.project_unit).make_available?
  end

  def update_scheme?(template_klass=nil)
    valid = record.project_unit_id.present? && "#{current_user_role_group}::ProjectUnitPolicy".constantize.new(user, record.project_unit).make_available?
    if template_klass.present?
      valid = valid && template_klass.where(booking_portal_client_id: user.booking_portal_client_id).count > 1
    end
    valid
  end

  def permitted_attributes params={}
    [:bedrooms, :carpet, :agreement_price, :all_inclusive_price, :project_unit_id, :project_tower_id, :floor, :step, :payment_schedule_template_id, :cost_sheet_template_id]
  end
end
