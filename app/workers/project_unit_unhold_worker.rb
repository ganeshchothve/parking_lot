class ProjectUnitUnholdWorker
  include Sidekiq::Worker

  def perform(unit_id)
    project_unit = ProjectUnit.find(unit_id)
    if project_unit.status == 'hold'
      project_unit.make_available
      SelldoLeadUpdater.perform_async(booking_detail.user_id, "hold_payment_dropoff")
      project_unit.save
    end
  end
end
