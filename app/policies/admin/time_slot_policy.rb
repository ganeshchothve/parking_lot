class Admin::TimeSlotPolicy < TimeSlotPolicy
  def index?
    super && %w[superadmin admin crm sales_admin sales cp_admin cp channel_partner gre].include?(user.role)
  end
end
