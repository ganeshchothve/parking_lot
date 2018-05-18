class ProjectUnitUnholdWorker
  include Sidekiq::Worker

  def perform(unit_id)
    project_unit = ProjectUnit.find(unit_id)
    if project_unit.status == 'hold'
      SelldoLeadUpdater.perform_async(project_unit.user_id.to_s, "hold_payment_dropoff")
      project_unit.make_available
      project_unit.save
    end
  end
end
