class BulkJobPolicy < ApplicationPolicy
  def index?
    user.role.in?(['admin', 'superadmin', 'sales'])
  end
end
