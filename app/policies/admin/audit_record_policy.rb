class Admin::AuditRecordPolicy < ApplicationPolicy
	def index?
    ['superadmin', 'admin'].include?(user.role)
  end
  def show?
  	index?
  end
end