class Admin::Audit::RecordPolicy < Audit::RecordPolicy
  def index?
    if current_client.real_estate?
      %w[superadmin admin].include?(user.role)
    else
      false
    end
  end
end
