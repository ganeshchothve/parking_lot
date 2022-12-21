class LeadPolicy < ApplicationPolicy

  def index?
    false
  end

  def new?
    false
  end

  def show?
    super
  end

  def permitted_attributes(params = {})
  end
end
