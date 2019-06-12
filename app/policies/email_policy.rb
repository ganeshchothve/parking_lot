class EmailPolicy < ApplicationPolicy
  class Scope < Scope
    # def self.find_child_ids(user)
    #   manager_ids = ids = [user.id]
    #   while User.in(manager_id: manager_ids).any?
    #     manager_ids = User.in(manager_id: manager_ids).pluck(:id)
    #     ids << manager_ids
    #   end
    #   ids.flatten!
    # end

    def resolve
      if %w[superadmin admin].include?(user.role)
        scope.all
      # elsif %w[cp channel_partner cp_admin].include?(user.role)
      #   scope.in(recipient_ids: Scope.find_child_ids(user))
      #   scope.in(recipient_ids: user.id) 
      elsif user.buyer? || %w[cp_admin sales_admin cp channel_partner sales].include?(user.role)
        scope.in(recipient_ids: user.id) 
      else 
        false
      end
    end
  end

  #def index? #Already inherited from Application Policy, returns false

  def show?
  end
end
