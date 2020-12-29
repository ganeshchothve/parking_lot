class Admin::TaskPolicy < TaskPolicy
  def permitted_attributes
    attributes = []
    if record.booking_detail.present?
      attributes += super if record.tracked_by == 'manual' && Admin::BookingDetailPolicy.new(user, record.booking_detail).editable_field?('tasks_attributes')
    else
      attributes += super
    end
    attributes
  end
end
