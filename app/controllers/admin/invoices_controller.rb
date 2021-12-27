class Admin::InvoicesController < AdminController
  before_action :set_resource, only: [:index, :new, :create]
  before_action :set_invoice, except: [:index, :create, :export]
  before_action :authorize_resource
  around_action :apply_policy_scope, only: [:index]

  def index
    @invoices = associated_class.build_criteria(params)
                       .asc(:ladder_stage)
                       .paginate(page: params[:page] || 1, per_page: params[:per_page])
  end

  def new
    render 'admin/invoices/new', layout: false
  end

  def create
    @invoice = Invoice::Manual.new(project: @resource.try(:project), raised_date: Time.now, invoiceable: @resource, manager: @resource.invoiceable_manager)
    @invoice.assign_attributes(permitted_attributes([current_user_role_group, @invoice]))
    respond_to do |format|
      if @invoice.save
        url = (@resource.present? ? admin_invoiceable_index_path(invoiceable_type: @resource.class.model_name.i18n_key.to_s, invoiceable_id: @resource.id, fltrs: { invoiceable_id: @resource.id }) : admin_invoices_path)
        format.html { redirect_to url, notice: t("controller.invoices.status_message.#{@invoice.status}") }
        format.json { render json: @invoice, notice: t("controller.invoices.status_message.#{@invoice.status}"), status: :created, location: url }
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

  def new_send_invoice_to_poc
    render 'admin/invoices/new_send_invoice_to_poc', layout: false
  end

  def send_invoice_to_poc
    attachments_attributes = []
    # File.open("#{Rails.root}/tmp/invoice_to_send_#{@invoice.id}.pdf", "wb") do |file|
    #   file << open(@invoice.assets.where(asset_type: 'system_generated_invoice').last.file.url).read
    # end
    # attachments_attributes << {file: File.open("#{Rails.root}/tmp/invoice_to_send_#{@invoice.id}.pdf")}
    email = Email.create!({
      project_id: @invoice.project.id,
      booking_portal_client_id: @invoice.project.booking_portal_client_id,
      email_template_id: Template::EmailTemplate.find_by(project_id: @invoice.project.id, name: "send_invoice_to_poc").id,
      to: [params[:email]],
      triggered_by_id: @invoice.id,
      triggered_by_type: @invoice.class.to_s
      # attachments_attributes: attachments_attributes
    })
    email.sent!
    @invoice.pending_approval!
    redirect_to admin_invoices_path, notice: "Successfully sent."
  end

  private

  def associated_class
    @associated_class = if params[:invoice_type] == 'calculated'
                          Invoice::Calculated
                        elsif params[:invoice_type] == 'manual'
                          Invoice::Manual
                        else
                          Invoice
                        end
  end

  def set_resource
    @resource = params[:invoiceable_type]&.classify&.constantize.where(id: params[:invoiceable_id]).first if params[:invoiceable_id].present?
  end

  def set_invoice
    if params[:action] == 'new'
      @invoice = Invoice::Manual.new(invoiceable: @resource, project_id: @resource.try(:project_id), agreement_amount: @resource.try(:calculate_invoice_agreement_amount))
    else
      @invoice = Invoice.where(id: params[:id]).first
    end
    redirect_to dashboard_path, alert: 'Invoice not found' unless @invoice.present?
  end

  def authorize_resource
    if params[:action].in?(%w(index create export))
      authorize [current_user_role_group, Invoice]
    elsif params[:action].in?(%w(change_state edit update raise_invoice update_gst new_send_invoice_to_poc))
      authorize [current_user_role_group, @invoice]
    else
      authorize [current_user_role_group, @invoice]
    end
  end

  def apply_policy_scope
    custom_scope = associated_class.where(Invoice.user_based_scope(current_user, params))
    associated_class.with_scope(policy_scope(custom_scope)) do
      yield
    end
  end
end
