class RegionPolicy < ApplicationPolicy
  def permitted_attributes
    attributes = %w[id _destroy]
    attributes += %w[city] if record.new_record?
    attributes += [partner_regions: []]
    attributes
  end
end
