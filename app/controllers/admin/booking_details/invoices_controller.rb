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
        format.html { redirect_to admin_booking_detail_invoices_path(@invoice.booking_detail), notice: t("controller.invoices.status_message.#{@invoice.status}") }
      else
        format.html { redirect_to admin_booking_detail_invoices_path(@invoice.booking_detail), alert: @invoice.errors.full_messages.uniq! }
      end
    end
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
    elsif params[:action].in?(%w(change_state edit update))
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
