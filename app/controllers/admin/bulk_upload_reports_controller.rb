class Admin::BulkUploadReportsController < AdminController
  before_action :authenticate_user!
  before_action :set_bulk_upload_report, only: [:show, :show_errors]

  def index
    @bulk_upload_reports = BulkUploadReport.all
    @bulk_upload_reports = @bulk_upload_reports.paginate(page: params[:page] || 1, per_page: params[:per_page])
    respond_to do |format|
      format.json { render json: @bulk_upload_reports }
      format.html {}
    end
  end

  def show
  end

  def show_errors
    @bulk_upload_report = BulkUploadReport.find(params[:id])
    @upload_error = @bulk_upload_report.upload_errors.find('5dff7a0b32b73541a6dc59a5')
  end

  def new
    @bulk_upload_report = BulkUploadReport.new
    render layout: false
  end
  
  def create
    @bulk_upload_report = BulkUploadReport.new
    @bulk_upload_report.assign_attributes(permitted_attributes([:admin, @bulk_upload_report]))
    if @bulk_upload_report.save
      filepath = "#{Rails.root}/public/uploads/asset/file/#{@bulk_upload_report.assets.first.id}/#{@bulk_upload_report.assets.first.file_name}"
      InventoryImport::Inventory.upload(filepath, current_client.id, @bulk_upload_report.id)
    else
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
      authorize [:admin, @channel_partner]
    end
  end

  def set_bulk_upload_report
    @bulk_upload_report = BulkUploadReport.find(params[:id]) 
  end
end