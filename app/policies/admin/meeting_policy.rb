class Admin::MeetingPolicy < MeetingPolicy
  def show?
    roles = ['superadmin', 'admin']
    roles += record.roles.reject{|x| x == 'channel_partner' || x == 'user'}
    if user.channel_partner.present? && user.channel_partner.active? && record.roles.include?('channel_partner')
      roles += ['channel_partner']
    end
    roles += User::ADMIN_ROLES
    roles -= %w[crm sales_admin sales channel_partner gre billing_team user employee_user management_user] unless ['scheduled', 'completed'].include?(record.status)
    roles.uniq.present?
  end

  def new?
    %w(admin superadmin).include?(user.role)
  end

  def create?
    new?
  end

  def edit?
    new?
  end

  def update?
    new? || (show? && record.status == 'scheduled')
  end

  def asset_create?
    new?
  end

  def permitted_attributes(_params = {})
    attributes = super + [:event]
    attributes += [:scheduled_on, :duration, roles: []]  if record.new_record? || !record.completed?
    attributes += [:provider, :provider_url, :campaign_id, :project_id, :topic, :meeting_type, :agenda, :duration, :broadcast] if record.new_record? || record.status == 'draft'
    attributes
  end
end
