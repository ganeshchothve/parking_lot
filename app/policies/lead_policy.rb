class LeadPolicy < ApplicationPolicy

  def index?
    false
  end

  def new?
    false
  end

  def show?
    if current_client.real_estate?
      super
    else
      false
    end
  end

  def permitted_attributes(params = {})
  end
end
