class Admin::BulkUploadReportsController < AdminController
  before_action :set_bulk_upload_report, only: [:show, :show_errors]
  before_action :authorize_resource

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