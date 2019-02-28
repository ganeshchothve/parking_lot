class Admin::SmsPolicy < SmsPolicy

  def index?
    !user.buyer?
  end

  def show?
    # if %w[superadmin admin crm sales_admin sales].include?(user.role)
    #   true
    # elsif %w[cp_admin cp channel_partner].include?(user.role)
    #   Scope.find_child_ids(user).include?(record.recipient_id)
    # else
    #   false
    # end
    !user.buyer?
  end
end
