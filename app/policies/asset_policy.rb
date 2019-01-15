class AssetPolicy < ApplicationPolicy

  def show?
    true
  end

  def index?
    true
  end

  def permitted_attributes params={}
    [ :file ]
  end
end
