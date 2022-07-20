class Admin::ReceiptsController < AdminController
  include ReceiptsConcern

  before_action :set_lead, except: %w[index show export resend_success edit_token_number update_token_number payment_mode_chart frequency_chart status_chart]
  before_action :set_receipt, only: %w[edit update show resend_success edit_token_number update_token_number]
  around_action :apply_policy_scope, only: :index

  # GET /admin/receipts/export
  # Defined in ReceiptsConcern

  # GET /admin/receipts/:receipt_id/resend_success
  # Defined in ReceiptsConcern

  #
  # This new action always create a new receipt form for user's project unit rerceipt form.
  #
  # GET "/admin/leads/:lead_id/receipts/new"
  def new
    @amount_hash = {}
    @lead.project.token_types.all.select{|tt| tt.incrementor_exists?}.map { |x| @amount_hash[x.id.to_s] = x.token_amount }

    @receipt = Receipt.new(
                      creator: current_user,
                      user: @lead.user,
                      lead: @lead,
                      project_id: @lead.project_id,
                      payment_mode: 'cheque',
                      payment_type: 'token',
                      total_amount: current_client.blocking_amount,
                      booking_portal_client_id: @lead.booking_portal_client_id
                    )
    authorize([:admin, @receipt])
    render layout: false
  end

  #
  # This new action always create a new receipt form for user's project unit rerceipt form.
  #
  # GET "admin/leads/:lead_id/receipts/lost_receipt"
  def lost_receipt
    @receipt = Receipt.new(creator: current_user, user: @lead.user, lead: @lead, project_id: @lead.project_id, payment_mode: 'online')
    authorize([:admin, @receipt])
    render layout: false
  end

  #
  # This create action always create a new receipt for user's project unit receipt form.
  #
  # POST /admin/leads/:lead_id/receipts
  def create
    @receipt = Receipt.new(
                      user: @lead.user,
                      lead: @lead,
                      creator: current_user,
                      project: @lead.project,
                      booking_portal_client_id: @lead.booking_portal_client_id
                      )
    @receipt.assign_attributes(permitted_attributes([:admin, @receipt]))
    @receipt.payment_gateway = current_client.payment_gateway if @receipt.payment_mode == 'online'
    @receipt.account ||= selected_account(current_client.payment_gateway.underscore, @receipt)
    authorize([:admin, @receipt])
    respond_to do |format|
      if @receipt.save
        flash[:notice] = 'Receipt was successfully updated. Please upload documents'
        if @receipt.payment_mode == 'online'
          if @receipt.payment_identifier.blank?
            url = @receipt.payment_gateway_service.gateway_url(@lead.get_search('').id)
          else
            url = admin_lead_receipts_path(@lead)
          end
        else
          url = admin_lead_receipts_path(@lead,'remote-state': assetables_path(assetable_type: @receipt.class.model_name.i18n_key.to_s, assetable_id: @receipt.id) )
        end
        format.json { render json: @receipt, location: url }
        format.html { redirect_to url }
      else
        flash[:alert] = @receipt.errors.full_messages
        format.json { render json: { errors: flash[:alert] }, status: :unprocessable_entity }
        format.html { render 'new' }
      end
    end
  end

  def show
    authorize([:admin, @receipt])
    render template: 'receipts/show'
  end

  def edit
    authorize([:admin, @receipt])
    render layout: false
  end

  def update
    authorize([:admin, @receipt])
    @receipt.assign_attributes(permitted_attributes([:admin, @receipt]))
    respond_to do |format|
      if @receipt.save
        format.html { redirect_to admin_lead_receipts_path(@lead), notice: 'Receipt was successfully updated.' }
      else
        format.html { render :edit }
        format.json { render json: { errors: @receipt.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def edit_token_number
    authorize([:admin, @receipt])
    render layout: false
  end

  def update_token_number
    authorize([:admin, @receipt])
    respond_to do |format|
      if @receipt.update(permitted_attributes([:admin, @receipt]))
        format.html { redirect_back fallback_location: root_path, notice: 'Receipt was successfully updated.' }
      else
        format.html { render :edit_token_number }
        format.json { render json: { errors: @receipt.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end
  #
  # GET /admin/receipts/payment_mode_chart
  #
  # This method is used in admin dashboard
  #
  def payment_mode_chart
    @data = DashboardData::AdminDataProvider.receipt_block(params)
    @statuses = params[:status] || %w[pending clearance_pending success available_for_refund]
    @dataset = get_dataset(@data, @statuses)
  end
  #
  # GET /admin/receipts/frequency_chart
  #
  # This method is used in admin dashboard
  #
  def frequency_chart
    @data = DashboardData::AdminDataProvider.receipt_frequency(params)
    @dataset = get_dataset_linechart(@data)
  end
  #
  # GET /admin/receipts/status_chart
  #
  # This method is used in admin dashboard
  #
  def status_chart
    @data = DashboardData::AdminDataProvider.receipt_piechart(params)
  end

  private

  def set_lead
    @lead = Lead.where(_id: params[:lead_id]).first
    redirect_to dashboard_path, alert: 'Lead Not found', status: 404 if @lead.blank?
  end

  def set_receipt
    @receipt = Receipt.where(_id: params[:id]).first
    redirect_to dashboard_path, alert: 'Receipt Not found', status: 404 if @receipt.blank?
  end

  def get_dataset(out, statuses)
    labels = Receipt::PAYMENT_MODES
    dataset = Array.new
    statuses.each_with_index do |status, index|
      d = Array.new
      labels.each do |l|
        if out[l.to_sym].present? && out[l.to_sym][status.to_sym].present?
          d << (out[l.to_sym][status.to_sym])
        else
          d << 0
        end
      end
      dataset << { label: t("mongoid.attributes.receipt/status.#{status}"),
        borderColor: '#ffffff',
        borderWidth: 1,
        data: d
      }
    end
    dataset
  end

  def get_dataset_linechart(out)
    payment_modes = %w[online offline]
    labels = out.keys
    dataset = Array.new
    payment_modes.each do |payment_mode|
      d = Array.new
      labels.each do |l|
        if out[l].present? && out[l][payment_mode.to_sym].present?
          d << (out[l][payment_mode.to_sym])
        else
          d << 0
        end
      end
      dataset << { label: t("mongoid.attributes.receipt/payment_mode.#{payment_mode}"),
        borderColor: '#ffffff',
        borderWidth: 1,
        data: d
      }
    end
    dataset
  end
end
