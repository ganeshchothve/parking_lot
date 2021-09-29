class MeetingPolicy < ApplicationPolicy
  def index?
    user.active_channel_partner?
  end

  def permitted_attributes(_params = {})
    record.scheduled? ? [:toggle_participant_id] : []
  end
end
