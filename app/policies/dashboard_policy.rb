class DashboardPolicy < Struct.new(:user, :dashboard)
  def index?
    true
  end

  def faqs?
    true
  end

  def documents?
    true
  end

  def rera?
    true
  end

  def tds_process?
    true
  end

  def terms_and_conditions?
    true
  end

  def gamify_unit_selection?
    true
  end
end
