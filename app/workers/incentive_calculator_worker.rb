class IncentiveCalculatorWorker
  include Sidekiq::Worker

  def perform booking_detail_id
    # Find booking detail
    booking_detail = BookingDetail.where(id: booking_detail_id).first
    if booking_detail
      incentive_calc = IncentiveCalculator.new(booking_detail)
      incentive_calc.calculate
    end
  end
end
