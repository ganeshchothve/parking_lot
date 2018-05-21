class DashboardPolicy < Struct.new(:user, :dashboard)
  def index?
    true
  end

  def project_units?
    true
  end

  def receipts?
    user.buyer?
  end

  def checkout?
    user.buyer?
  end

  def update_project_unit?
    user.buyer?
  end

  def hold_project_unit?
    user.buyer?
  end

  def update_co_applicants?
    user.buyer?
  end
end
