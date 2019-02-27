class Admin::EmailPolicy < EmailPolicy

  def index?
    true
  end

  def show?
    true
  end
end
