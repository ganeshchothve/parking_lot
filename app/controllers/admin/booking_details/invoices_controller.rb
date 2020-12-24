class Admin::BookingDetails::InvoicesController < AdminController
  before_action :set_booking_detail
  before_action :set_invoice, except: :index
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

  def re_raise
    render 'admin/invoices/re_raise', layout: false
  end

  def show
    render 'admin/invoices/show'
  end

  def edit
    render 'admin/invoices/edit', layout: false
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

  private

  def set_booking_detail
    @booking_detail = BookingDetail.where(id: params[:booking_detail_id]).first if params[:booking_detail_id].present?
  end

  def set_invoice
    @invoice = Invoice.where(id: params[:id]).first
    redirect_to dashboard_path, alert: 'Invoice not found' unless @invoice.present?
  end

  def authorize_resource
    if params[:action] == 'index'
      authorize [current_user_role_group, Invoice]
    elsif params[:action].in?(%w(change_state edit update re_raise))
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
