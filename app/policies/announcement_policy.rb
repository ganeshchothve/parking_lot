class AnnouncementPolicy < ApplicationPolicy
  def index?
    user.active_channel_partner? && !user.role?('dev_sourcing_manager')
  end

  def permitted_attributes(_params = {})
    record.scheduled? ? [:toggle_participant_id] : []
  end
end
