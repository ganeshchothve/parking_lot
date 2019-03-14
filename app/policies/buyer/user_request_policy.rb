class Buyer::UserRequestPolicy < UserRequestPolicy
  # def index? from UserRequestPolicy

  def new?
    valid = true
    valid = (record.project_unit.user_based_status(user) == 'booked' && record.project_unit.status != 'hold') && UserRequest.where(project_unit_id: record.project_unit_id).where(status: 'pending').blank? if record.project_unit_id.present?
    valid &&= (user.buyer? && record.user_id == user.id)
  end

  def edit?
    user.id == record.user_id && record.status == 'pending'
  end

  def update?
    edit?
  end

  def permitted_attributes(_params = {})
    attributes = []
    if record.status == 'pending' && user.buyer?
      attributes += %i[receipt_id user_id]
      attributes += %i[project_unit_id booking_detail_id event] if record.new_record?
      attributes += [notes_attributes: Buyer::NotePolicy.new(user, Note.new).permitted_attributes]
    end
    attributes
  end
end
