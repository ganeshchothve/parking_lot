class Buyer::TimeSlotPolicy < TimeSlotPolicy
  def index?
    user.buyer?
  end
end
