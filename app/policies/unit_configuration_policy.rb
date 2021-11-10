class UnitConfigurationPolicy < ApplicationPolicy

  def asset_create?
    edit?
  end
end
