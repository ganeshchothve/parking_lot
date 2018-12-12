class EmailPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.in(recipient_ids: user.id) if %w[user employee_user management_user].include?(user.role)
    end
  end

  def index?
    true if %w[user employee_user management_user].include?(user.role)
  end

  def show?
    record.recipient_ids.include?(user.id)
  end
end
