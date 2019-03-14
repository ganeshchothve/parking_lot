class ProjectUnitUnholdWorker
  include Sidekiq::Worker

  def perform(unit_id)
    project_unit = ProjectUnit.find(unit_id)
    if project_unit.status == 'hold'
      project_unit.booking_detail.booking_detail_schemes.destroy
      project_unit.booking_detail.destroy
      project_unit.make_available
      project_unit.save
    end
  end
end
