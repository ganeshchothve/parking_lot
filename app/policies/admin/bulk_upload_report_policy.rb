class Admin::BulkUploadReportPolicy < AccountPolicy
  def index?
    %w[superadmin admin].include?(user.role)
  end

  def show?
    index?
  end

  def show_errors?
    index?
  end

  def new?
    index?
  end

  def create?
    index?
  end
  
  def permitted_attributes
    attributes = %i[uploaded_by_id total_rows success_count failure_count]
    attributes += [assets_attributes: AssetPolicy.new(user, (record.assets.last || Asset.new) ).permitted_attributes]
  end
end
