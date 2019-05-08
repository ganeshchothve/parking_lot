class Buyer::UserRequestPolicy < UserRequestPolicy
  # def index? from UserRequestPolicy

  def new?
    valid = current_client.enable_actual_inventory?(user)
    if record.requestable.present? && record.requestable_type == 'BookingDetail'
      valid &&= BookingDetail::BOOKING_STAGES.include?(record.requestable.status)
    end
    valid
  end

  def edit?
    user.id == record.user_id && record.status == 'pending'
  end

  def update?
    edit?
  end

  def permitted_attributes(_params = {})
    attributes = []
    if record.status == 'pending'
      attributes += %i[receipt_id user_id]
      attributes += %i[requestable_id]
      attributes += %i[project_unit_id requestable_type event] if record.new_record?
      attributes += [notes_attributes: Buyer::NotePolicy.new(user, Note.new).permitted_attributes]
    end
    attributes
  end
end
