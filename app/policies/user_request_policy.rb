class UserRequestPolicy < ApplicationPolicy
  # def edit? def update? def new? def create? def permitted_attributes from ApplicationPolicy

  def index?
    out = user.booking_portal_client.enable_actual_inventory?(user) || enable_incentive_module?(user)
    out && user.active_channel_partner?
  end

  def update?
    false
  end

  def create?
    new?
  end

  def asset_create?
    create?
  end

  def export?
    false
  end

  private

  def new_permission_by_requestable_type
    case record.requestable_type
    when 'BookingDetail'
      record&.lead&.project && enable_actual_inventory?(user) && BookingDetail::BOOKING_STAGES.include?(record.requestable.status)
    when 'Receipt'
      record.lead.project&.is_active? && enable_actual_inventory?(user) && record.requestable.success? && record.requestable.booking_detail_id.blank?
    else
      true
    end
  end
end
