class OfferPolicy < ApplicationPolicy
  def permitted_attributes
    attributes = super
    attributes += [:id, :category, :short_description, :description, :provided_by, :booking_portal_client_id]
    attributes += [:_destroy] if record.id.present?
    attributes.uniq
  end
end
