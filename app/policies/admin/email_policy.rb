class Admin::EmailPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all if ['superadmin', 'admin', 'crm', 'sales_admin', 'sales'].include?(user.role) 
    end
  end

  def show?
    true
  end
end
