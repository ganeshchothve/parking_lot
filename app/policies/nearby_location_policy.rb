class NearbyLocationPolicy < ApplicationPolicy
  def permitted_attributes
    attributes = super
    attributes += [:id, :distance, :unit, :destination, :booking_portal_client_id]
    attributes += [:_destroy] if record.id.present?
    attributes.uniq
  end
end
