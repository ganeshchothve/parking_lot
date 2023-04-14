class BulkJobPolicy < ApplicationPolicy
  def index?
    user.role.in?(['admin', 'superadmin', 'sales']) && marketplace_client?
  end
end
