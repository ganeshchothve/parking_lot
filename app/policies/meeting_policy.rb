class MeetingPolicy < ApplicationPolicy
  def index?
    if current_client.real_estate?
      user.active_channel_partner? && !%w(account_manager account_manager_head billing_team dev_sourcing_manager).include?(user.role)
    else
      false
    end
  end

  def permitted_attributes(_params = {})
    record.scheduled? ? [:toggle_participant_id] : []
  end
end
