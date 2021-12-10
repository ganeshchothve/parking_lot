class Admin::AnnouncementPolicy < AnnouncementPolicy
  def show?
    ['channel_partner', 'cp_owner'].include?(user.role)
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
    new? || show?
  end

  def asset_create?
    new?
  end

  # def permitted_attributes(_params = {})
  #   attributes = super + [:event]
  #   attributes += [:scheduled_on, :duration, roles: []]  if record.new_record? || !record.completed?
  #   attributes += [:provider, :provider_url, :campaign_id, :project_id, :topic, :meeting_type, :agenda, :duration, :broadcast] if record.new_record? || record.status == 'draft'
  #   attributes
  # end
end
