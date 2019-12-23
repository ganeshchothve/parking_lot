class BulkUploadReporttPolicy < ApplicationPolicy
  
  def index?
    user.role?('superadmin')
  end

  def create?
    new?
  end
end
