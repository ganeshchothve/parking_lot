class Admin::SyncLogPolicy < SyncLogPolicy
  include ApplicationHelper
  def index?
    %w[superadmin admin sales_admin].include?(user.role)
  end

  def resync?
    %w[superadmin admin sales_admin].include?(user.role) && (current_client.selldo_client_id.blank? && current_client.selldo_form_id.blank?)
  end
end
