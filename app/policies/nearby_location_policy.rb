class NearbyLocationPolicy < ApplicationPolicy
  def permitted_attributes
    attributes = super
    attributes += [:id, :distance, :destination]
    attributes += [:_destroy] if record.id.present?
    attributes.uniq
  end
end
