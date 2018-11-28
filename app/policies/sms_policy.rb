class SmsPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.in(recipient_id: user.id) if ['user', 'employee_user', 'management_user'].include?(user.role)
    end
  end

  def show?
    record.recipient_id == user.id
  end
end
