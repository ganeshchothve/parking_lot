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

  def permitted_attributes(params = {})
    attributes = super || []
    if user.role.in?(%w(admin cp_admin))
      attributes += [:count_status, :expiry_date]
    end
  end
end
