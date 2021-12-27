class IncentiveCalculatorWorker
  include Sidekiq::Worker

  def perform resource_class, resource_id
    # Find booking detail
    resource = resource_class.classify&.constantize&.where(id: resource_id)&.first
    if resource
      incentive_calc = IncentiveCalculator.new(resource)
      incentive_calc.calculate
    end
  end
end
