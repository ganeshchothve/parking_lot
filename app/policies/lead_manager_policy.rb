class LeadManagerPolicy < ApplicationPolicy
  # def edit? def update? def new? def create? def permitted_attributes from ApplicationPolicy

  def index?
    false
  end

  def permitted_attributes(params = {})
    attributes = super || []
    #attributes += [:sitevisit_status, :sitevisit_date]
    if user.role.in?(%w(superadmin admin cp_admin cp sales_admin))
      attributes += [:expiry_date]
    end
  end
end
