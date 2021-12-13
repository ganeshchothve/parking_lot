class MeetingPolicy < ApplicationPolicy
  def index?
    user.active_channel_partner? && !%w(account_manager account_manager_head billing_team dev_sourcing_manager).include?(user.role)
  end

  def permitted_attributes(_params = {})
    record.scheduled? ? [:toggle_participant_id] : []
  end
end
