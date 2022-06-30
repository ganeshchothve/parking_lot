class BulkUpdateBookingPriceWorker
  include Sidekiq::Worker

  def perform project_id
    project = Project.find(project_id)
    if project.booking_price_in_percentage
        project.project_units.each do |pu|
            pu.set(booking_price: pu.set_booking_price)
        end
    else
    project.project_units.update_all(booking_price: project.booking_price_factor)
    end
  end

end