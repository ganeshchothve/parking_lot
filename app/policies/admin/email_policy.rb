class Admin::EmailPolicy < EmailPolicy

  def index?
    !user.buyer?
  end

  def show?
    !user.buyer?
  end
end
