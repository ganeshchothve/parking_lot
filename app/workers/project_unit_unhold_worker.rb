class ProjectUnitUnholdWorker
  include Sidekiq::Worker

  def perform(unit_id)
    project_unit = ProjectUnit.find(unit_id)
    if project_unit.status == 'hold'
      hold_bookings = project_unit.booking_details.where(status: 'hold')
      lead = hold_bookings.first.try(:lead)
      hold_bookings.destroy_all
      project_unit.make_available(lead)
      project_unit.save ? true : { errors: project_unit.errors.full_messages.uniq.join('\n') }
   else
     { errors: I18n.t("worker.project_units.errors.not_on_hold") }
    end
  end
end
