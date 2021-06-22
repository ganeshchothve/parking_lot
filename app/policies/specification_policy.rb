class SpecificationPolicy < ApplicationPolicy
  def permitted_attributes
    attributes = super
    attributes += [:id, :category, :description]
    attributes += [:_destroy] if record.id.present?
    attributes.uniq
  end
end
