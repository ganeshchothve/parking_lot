class Admin::EmailPolicy < ApplicationPolicy
  class Scope < Scope
    def self.find_child_ids(user)
      manager_ids = ids = [user.id]
      while(User.in(manager_id: manager_ids).count!=0)
        manager_ids = User.in(manager_id: manager_ids).pluck(:id)
        ids << manager_ids
      end
      ids.flatten!
    end

    def resolve
      if ['superadmin', 'admin', 'crm', 'sales_admin', 'sales'].include?(user.role) 
        scope.all 
      elsif ['cp_admin', 'cp', 'channel_partner'].include?(user.role)
        scope.in(recipient_ids: Scope.find_child_ids(user))
      end
    end
  end

  def show?
    if ['superadmin', 'admin', 'crm', 'sales_admin', 'sales'].include?(user.role)
      true
    elsif ['cp_admin', 'cp', 'channel_partner'].include?(user.role)
      !(record.recipient_ids & Scope.find_child_ids(user)).empty?
    else
      false
    end
  end
end
