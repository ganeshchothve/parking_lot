class Admin::BookingDetails::InvoicesController < AdminController
  before_action :set_booking_detail
  before_action :set_invoice, except: [:index, :create, :export]
  before_action :authorize_resource
  around_action :apply_policy_scope, only: [:index]

  def index
    @invoices = Invoice.build_criteria(params)
                       .asc(:ladder_stage)
                       .paginate(page: params[:page] || 1, per_page: params[:per_page])
    respond_to do |format|
      format.html { render template: (@booking_detail.present? ? 'booking_details/invoices/index' : 'admin/invoices/index') }
    end
  end

  def new
    render 'admin/invoices/new', layout: false
  end

  def create
    @invoice = @booking_detail.invoices.build(project: @booking_detail.project, manager: @booking_detail.manager, raised_date: Time.now)
    @invoice.assign_attributes(permitted_attributes([current_user_role_group, @invoice]))
    respond_to do |format|
      if @invoice.save
        format.html { redirect_to request.referer, notice: t("controller.invoices.status_message.#{@invoice.status}") }
        format.json { render json: @invoice, notice: t("controller.invoices.status_message.#{@invoice.status}"), status: :created, location: admin_invoices_path("remote-state": assetables_path(assetable_type: @invoice.class.model_name.i18n_key.to_s, assetable_id: @invoice.id, asset_header: t('controller.invoices.asset_create.link_name'))) }
      else
        format.html { redirect_to request.referer, alert: @invoice.errors.full_messages.uniq }
        format.json { render json: { errors: @invoice.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end

  def change_state
    respond_to do |format|
      if @invoice.update(permitted_attributes([current_user_role_group, @invoice]))
        format.html { redirect_to request.referer, notice: t("controller.invoices.status_message.#{@invoice.status}") }
      else
        format.html { redirect_to request.referer, alert: @invoice.errors.full_messages.uniq }
        format.json { render json: { errors: @invoice.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end

  def raise_invoice
    render 'admin/invoices/raise_invoice', layout: false
  end

  def show
    render 'admin/invoices/show'
  end

  def edit
    @invoice.build_payment_adjustment unless @invoice.payment_adjustment.present?
    render 'admin/invoices/edit', layout: false
  end

  def update_gst
    render 'admin/invoices/update_gst', layout: false
  end

  def update
    respond_to do |format|
      if @invoice.update(permitted_attributes([current_user_role_group, @invoice]))
        format.json { render json: @invoice, status: :ok }
      else
        format.json { render json: { errors: @invoice.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end

  def generate_invoice
    respond_to do |format|
      format.html do
        render template: "admin/invoices/generate_invoice"
      end
      format.pdf do
        pdf_html = render_to_string(template: 'admin/invoices/generate_invoice', layout: 'pdf')
        pdf = WickedPdf.new.pdf_from_string(pdf_html, viewport_size: '1280x1024', page_size: 'A4', zoom: 1, dpi: 100, lowquality: true)
        send_data pdf, filename: "invoice-#{DateTime.current.strftime('%d-%m-%Y %T')}.pdf"
      end
    end
  end

  def export
    if Rails.env.development?
      BrokerageExportWorker.new.perform(current_user.id.to_s, params[:fltrs])
    else
      BrokerageExportWorker.perform_async(current_user.id.to_s, params[:fltrs].as_json)
    end
    flash[:notice] = 'Your export has been scheduled and will be emailed to you in some time'
    redirect_to admin_invoices_path(fltrs: params[:fltrs].as_json)
  end

  private

  def set_booking_detail
    @booking_detail = BookingDetail.where(id: params[:booking_detail_id]).first if params[:booking_detail_id].present?
  end

  def set_invoice
    if params[:action] == 'new'
      @invoice = @booking_detail.invoices.build
    else
      @invoice = Invoice.where(id: params[:id]).first
    end
    redirect_to dashboard_path, alert: 'Invoice not found' unless @invoice.present?
  end

  def authorize_resource
    if params[:action].in?(%w(index create export))
      authorize [current_user_role_group, Invoice]
    elsif params[:action].in?(%w(change_state edit update raise_invoice update_gst))
      authorize [current_user_role_group, @invoice]
    else
      authorize [current_user_role_group, @invoice]
    end
  end

  def apply_policy_scope
    custom_scope = Invoice.where(Invoice.user_based_scope(current_user, params))
    Invoice.with_scope(policy_scope(custom_scope)) do
      yield
    end
  end
end
