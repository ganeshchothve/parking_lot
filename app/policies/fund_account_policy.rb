class FundAccountPolicy < ApplicationPolicy

  def permitted_attributes(params = {})
    attrs = []
    attrs += [:id]
    attrs += [:address] unless record.is_active?
    attrs += [:is_active] if user.role.in?(%w(cp cp_admin admin superadmin))
    attrs
  end
end
