class CostObserver < Mongoid::Observer
  def before_validation cost
  end
end