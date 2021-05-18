class LeadPolicy < ApplicationPolicy

  def index?
    false
  end

  def new?
    false
  end

end
