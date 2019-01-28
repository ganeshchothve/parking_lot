class BookingDetailPolicy < ApplicationPolicy
  # we allow only admin and user role people to access the update action for uploading files
  def update?
    %w[superadmin admin user].include?(user.role)
  end

  def permitted_attributes(_params = {})
    attributes = [:tds_doc]
    attributes += [:erp_id] if %w[admin sales_admin].include?(user.role)
  end
end
