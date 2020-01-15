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

  def new?
    index?
  end

  def create?
    index?
  end

  def download_file?
    index?
  end
  
  def permitted_attributes
    attributes = %i[uploaded_by_id total_rows success_count failure_count]
    attributes += [asset_attributes: AssetPolicy.new(user, (record.asset || Asset.new) ).permitted_attributes]
  end
end
