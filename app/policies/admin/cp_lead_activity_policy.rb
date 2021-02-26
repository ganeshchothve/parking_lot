class Admin::CpLeadActivityPolicy < CpLeadActivityPolicy
  def index?
    true
  end

  def update?
    %w(admin cp_admin).include?(user.role)
  end

  def edit?
    update?
  end

  def show?
    true
  end

  def asset_create?
    user.role?(:channel_partner)
  end
end
