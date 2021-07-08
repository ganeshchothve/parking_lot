class TimelineUpdatePolicy < ApplicationPolicy
  def permitted_attributes
    attributes = super
    attributes += [:id, :name, :date, :description]
    attributes += [:_destroy] if record.id.present?
    attributes.uniq
  end
end
