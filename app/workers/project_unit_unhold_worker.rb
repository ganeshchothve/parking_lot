class ProjectUnitUnholdWorker
  include Sidekiq::Worker

  def perform(unit_id)
    project_unit = ProjectUnit.find(unit_id)
    if project_unit.status == 'hold'
      project_unit.status = 'available'
      project_unit.save
    end
  end
end
