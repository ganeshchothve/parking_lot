class DatumPolicy < ApplicationPolicy
  def permitted_attributes params={}
    [:id, :name, :key, :absolute_value, :order, :formula, :_destroy]
  end
end
