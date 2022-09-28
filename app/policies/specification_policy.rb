class SpecificationPolicy < ApplicationPolicy
  def permitted_attributes
    attributes = super
    attributes += [:id, :category, :description, :booking_portal_client_id]
    attributes += [:_destroy] if record.id.present?
    attributes.uniq
  end
end
