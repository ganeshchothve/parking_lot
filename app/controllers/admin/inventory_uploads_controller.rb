class Admin::InventoryUploadsController < AdminController
  def bulk_upload
    @bulk_upload_report = BulkUploadReport.new
  end
end
