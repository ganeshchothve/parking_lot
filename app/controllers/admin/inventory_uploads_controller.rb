class Admin::InventoryUploadsController < AdminController
	before_action :authorize_resource
  def new
    @bulk_upload_report = BulkUploadReport.new
  end

  def create
    @bulk_upload_report = BulkUploadReport.new
    @bulk_upload_report.assign_attributes(permitted_attributes([:admin, @bulk_upload_report]))
    respond_to do |format|
      if @bulk_upload_report.save
        filepath = @bulk_upload_report.asset.file.file.file
        BulkUpload::Inventory.upload(filepath, current_client.id, @bulk_upload_report.id)
        format.html {}
        format.json {}
      else
        format.html { redirect_to new_admin_inventory_upload_path, alert: @bulk_upload_report.errors.full_messages.uniq }
        format.json { render json: { errors: @bulk_upload_report.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end

  private
  def authorize_resource
    if params[:action] == 'index'
      authorize [:admin, BulkUploadReport]
    elsif params[:action] == 'new'
      authorize [:admin, BulkUploadReport.new]
    elsif params[:action] == 'create'
      authorize [:admin, BulkUploadReport.new(permitted_attributes([:admin, BulkUploadReport.new]))]
    else
      authorize [:admin, @bulk_upload_report]
    end
  end
end
