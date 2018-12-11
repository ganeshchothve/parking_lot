class Admin::EmailPolicy < ApplicationPolicy
  class Scope < Scope
    def self.find_child_ids(user)
      manager_ids = ids = [user.id]
      while User.in(manager_id: manager_ids).any?
        manager_ids = User.in(manager_id: manager_ids).pluck(:id)
        ids << manager_ids
      end
      ids.flatten!
    end

    def resolve
      if %w[superadmin admin crm sales_admin sales].include?(user.role)
        scope.all
      elsif %w[cp_admin cp channel_partner].include?(user.role)
        scope.in(recipient_ids: Scope.find_child_ids(user))
      else
        false
      end
    end
  end

  def index?
    true if %w[superadmin admin crm sales_admin sales cp_admin cp channel_partner].include?(user.role)
  end

  def show?
    if %w[superadmin admin crm sales_admin sales].include?(user.role)
      true
    elsif %w[cp_admin cp channel_partner].include?(user.role)
      !(record.recipient_ids & Scope.find_child_ids(user)).empty?
    else
      false
    end
  end
end
