class TimeSlotPolicy < ApplicationPolicy
  # def index? from ApplicationPolicy

  def index?
    current_client.enable_slot_generation?
  end

end
