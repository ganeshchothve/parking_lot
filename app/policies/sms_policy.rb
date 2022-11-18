class SmsPolicy < ApplicationPolicy
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
      if (%w[superadmin admin]).include?(user.role)
        scope.all
      # elsif %w[cp_admin cp channel_partner].include?(user.role)
      #   scope.in(recipient_id: Scope.find_child_ids(user))
      elsif %w[cp_admin cp channel_partner billing_team sales_admin sales].include?(user.role)
        if user.active_channel_partner?
          scope.in(recipient_ids: user.id)
        else
          false
        end
      else
        false
      end
    end
  end

  #def index? #Already inherited from Application Policy, returns false

  def show?
  end
end
