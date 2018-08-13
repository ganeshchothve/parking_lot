class CostPolicy < ApplicationPolicy
  def permitted_attributes params={}
    [:id, :name, :absolute_value, :order, :formula, :category, :_destroy]
  end
end
