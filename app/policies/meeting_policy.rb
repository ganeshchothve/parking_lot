class MeetingPolicy < ApplicationPolicy
  def index?
    true
  end

  def permitted_attributes(_params = {})
    record.scheduled? ? [:toggle_participant_id] : []
  end
end
