class BulkUploadReportPolicy < ApplicationPolicy
  def index?
    user.role?('superadmin')
  end

  def create?
    new?
  end

  def asset_create?
    new?
  end
end
