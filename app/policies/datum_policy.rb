class DatumPolicy < ApplicationPolicy
  def permitted_attributes params={}
    [:id, :name, :absolute_value, :order, :formula, :_destroy]
  end
end
