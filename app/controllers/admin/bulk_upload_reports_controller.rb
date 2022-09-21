class Admin::BulkUploadReportsController < AdminController
  before_action :set_bulk_upload_report, only: [:show, :show_errors, :upload_error_exports]
  before_action :authorize_resource
  around_action :apply_policy_scope, only: %i[index]

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

  def new
    @bulk_upload_report = BulkUploadReport.new
    render layout: false
  end

  def create
    @bulk_upload_report = BulkUploadReport.new(uploaded_by: current_user)
    @bulk_upload_report.assign_attributes(permitted_attributes([:admin, @bulk_upload_report]))
    if current_user.role?(:admin)
      @bulk_upload_report.assign_attributes(client_id: current_user.booking_portal_client_id)
    elsif current_user.role?(:superadmin)
      @bulk_upload_report.assign_attributes(client_id: current_user.selected_client_id)
    end
    respond_to do |format|
      if @bulk_upload_report.save
        if Rails.env.development?
          BulkUploadWorker.new.perform(@bulk_upload_report.id)
        else
          BulkUploadWorker.perform_async(@bulk_upload_report.id)
        end
        format.html { redirect_to admin_bulk_upload_reports_path, notice: t('controller.bulk_upload_reports.create.success', upload_type: t("mongoid.attributes.bulk_upload_report/file_types.#{ @bulk_upload_report.asset.try(:document_type) || 'bulk_upload' }")) }
      else
        format.html { redirect_to admin_bulk_upload_reports_path, alert: @bulk_upload_report.errors.full_messages.uniq }
      end
    end
  end

  def upload_error_exports
    if Rails.env.staging? || Rails.env.production?
      UploadErrorsExportWorker.perform_async(current_user.id.to_s, @bulk_upload_report.id.to_s)
    else
      UploadErrorsExportWorker.new.perform(current_user.id.to_s, @bulk_upload_report.id.to_s)
    end
    flash[:notice] = 'Your export has been scheduled and will be emailed to you in some time'
    redirect_to admin_bulk_upload_report_path
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

  def apply_policy_scope
    custom_scope = BulkUploadReport.where(BulkUploadReport.user_based_scope(current_user, params))
    BulkUploadReport.with_scope(policy_scope(custom_scope)) do
      yield
    end
  end
end
