class PaymentTypePolicy < ApplicationPolicy
  # def edit? def update? def new? def create? def permitted_attributes from ApplicationPolicy

  def permitted_attributes(params = {})
    [:name, :project_id, :absolute_value, :formula]
  end
end
