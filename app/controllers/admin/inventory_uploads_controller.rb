class Admin::InventoryUploadsController < Admin::BulkUploadReportsController
	before_action :authenticate_user!
  def new
    @bulk_upload_report = BulkUploadReport.new
  end

  def create
    @bulk_upload_report = BulkUploadReport.new
    @bulk_upload_report.assign_attributes(permitted_attributes([:admin, @bulk_upload_report]))
    if @bulk_upload_report.save
      filepath = @bulk_upload_report.asset.file.file.file
      BulkUpload::Inventory.upload(filepath, current_client.id, @bulk_upload_report.id)
    else
      format.html { render :new }
      format.json { render json: { errors: @bulk_upload_report.errors.full_messages.uniq }, status: :unprocessable_entity }
    end
  end
end
