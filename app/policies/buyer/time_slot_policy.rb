class Buyer::TimeSlotPolicy < TimeSlotPolicy
  def index?
    super && user.buyer?
  end
end
