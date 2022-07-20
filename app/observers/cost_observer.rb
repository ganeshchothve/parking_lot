class CostObserver < Mongoid::Observer
  def before_validation cost
    cost.booking_portal_client_id = cost.costable.booking_portal_client_id
  end
end