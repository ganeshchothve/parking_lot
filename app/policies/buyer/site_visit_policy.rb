class Buyer::SiteVisitPolicy < SiteVisitPolicy
  def index?
    false
  end

  def edit?
    false
  end

  def new?
    false
  end

  def show?
    edit?
  end

  def update?
    edit?
  end

  def create?
    new?
  end

  def sync?
    edit?
  end
end
