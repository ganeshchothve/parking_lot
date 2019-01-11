class UnitConfigurationPolicy < ApplicationPolicy

  def asset_create?
    create?
  end
end