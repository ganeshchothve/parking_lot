class ProjectUnitUnholdWorker
  include Sidekiq::Worker

  def perform(unit_id)
    project_unit = ProjectUnit.find(unit_id)
    if project_unit.status == 'hold'
      project_unit.booking_details.where(status: 'hold').destroy_all
      project_unit.make_available
      project_unit.save ? true : { errors: project_unit.errors.full_messages.uniq.join(‘\n’) }
   else
     { errors: ‘Project unit not on hold’ }
    end
  end
end
