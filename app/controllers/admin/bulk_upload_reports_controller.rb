class Admin::BulkUploadReportsController < AdminController
  before_action :set_bulk_upload_report, only: [:show, :show_errors]
  before_action :authenticate_user!

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
    @upload_error = @bulk_upload_report.upload_errors.find(params[:upload_error_id])
  end

  def new
    @bulk_upload_report = BulkUploadReport.new
    render layout: false
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

  def set_bulk_upload_report
    @bulk_upload_report = BulkUploadReport.find(params[:id]) 
  end
end