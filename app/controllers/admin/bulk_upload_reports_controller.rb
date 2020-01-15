class Admin::BulkUploadReportsController < AdminController
  before_action :set_bulk_upload_report, only: [:show, :show_errors, :download_file]
  before_action :authorize_resource

  def index
    @bulk_upload_reports = BulkUploadReport.all.order('created_at DESC')
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

  def download_file
    if Rails.env.development?
      send_file(open(@bulk_upload_report.asset.file.file.file),
          :filename => "inventory_#{@bulk_upload_report.asset.file.file.original_filename}",
          :type => @bulk_upload_report.asset.file.content_type,
          :disposition => 'attachment',
          :url_based_filename => true)
    else
      send_file(open(@bulk_upload_report.asset.file.url),
          :filename => "Brochure.#{@bulk_upload_report.asset.file.file.filename}",
          :type => @bulk_upload_report.asset.file.content_type,
          :disposition => 'attachment',
          :url_based_filename => true)
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