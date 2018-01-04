class DashboardPolicy < Struct.new(:user, :dashboard)
  def index?
    true
  end

  def project_units?
    true
  end

  def receipts?
    user.role?('user')
  end

  def checkout?
    user.role?('user')
  end

  def update_project_unit?
    user.role?('user')
  end

  def hold_project_unit?
    user.role?('user')
  end
end
