class IncentiveCalculatorWorker
  include Sidekiq::Worker

  def perform resource_class, resource_id, category
    # Find booking detail
    resource = resource_class.classify&.constantize&.where(id: resource_id)&.first
    if resource
      incentive_calc = IncentiveCalculator.new(resource, category)
      incentive_calc.calculate
    end
  end
end
