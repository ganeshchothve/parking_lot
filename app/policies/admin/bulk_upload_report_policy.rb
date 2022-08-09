class Admin::BulkUploadReportPolicy < BulkUploadReportPolicy
  def index?
    %w[superadmin admin].include?(user.role)
  end

  def show?
    index?
  end

  def show_errors?
    index?
  end

  def upload_error_exports?
    index?
  end

  def new?
    index?
  end

  def create?
    index?
  end

  def download_file?
    index?
  end

  def bulk_upload?
    index?
  end

  def asset_create?
    index?
  end

  def permitted_attributes
    attributes = [:project_id, asset_attributes: AssetPolicy.new(user, (record.asset || Asset.new) ).permitted_attributes]
  end
end
