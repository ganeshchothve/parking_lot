class Admin::ReceiptsController < AdminController
  include ReceiptsConcern

  before_action :set_user, except: %w[index show export resend_success edit_token_number update_token_number receipt_barchart receipt_linechart receipt_piechart]
  before_action :set_receipt, only: %w[edit update show resend_success edit_token_number update_token_number]

  #
  # This index action for Admin users where Admin can view all receipts.
  #
  #
  # @return [{},{}] records with array of Hashes.
  # GET /admin/receipts
  def index
    authorize([:admin, Receipt])
    @receipts = Receipt.where(Receipt.user_based_scope(current_user, params))
                       .build_criteria(params)
                       .paginate(page: params[:page] || 1, per_page: params[:per_page])
    respond_to do |format|
      format.json { render json: @receipts.as_json(methods: [:name]) }
      format.html
    end
  end

  # GET /admin/receipts/export
  # Defined in ReceiptsConcern

  # GET /admin/receipts/:receipt_id/resend_success
  # Defined in ReceiptsConcern

  #
  # This new action always create a new receipt form for user's project unit rerceipt form.
  #
  # GET "/admin/users/:user_id/receipts/new"
  def new
    @receipt = Receipt.new(
      creator: current_user, user_id: @user, payment_mode: 'cheque',
      total_amount: current_client.blocking_amount
    )
    authorize([:admin, @receipt])
    render layout: false
  end

  #
  # This new action always create a new receipt form for user's project unit rerceipt form.
  #
  # GET "admin/users/:user_id/receipts/lost_receipt"
  def lost_receipt
    @receipt = Receipt.new(creator: current_user, user_id: @user, payment_mode: 'online')
    authorize([:admin, @receipt])
    render layout: false
  end

  #
  # This create action always create a new receipt for user's project unit receipt form.
  #
  # POST /admin/users/:user_id/receipts
  def create
    @receipt = Receipt.new(user: @user, creator: current_user, project_unit_id: params.dig(:receipt, :project_unit_id))
    @receipt.assign_attributes(permitted_attributes([:admin, @receipt]))
    @receipt.payment_gateway = current_client.payment_gateway if @receipt.payment_mode == 'online'
    @receipt.account ||= selected_account(current_client.payment_gateway.underscore)
    authorize([:admin, @receipt])
    respond_to do |format|
      if @receipt.save
        flash[:notice] = 'Receipt was successfully updated. Please upload documents'
        if @receipt.payment_mode == 'online'
          if @receipt.payment_identifier.blank?
            url = @receipt.payment_gateway_service.gateway_url(@user.get_search('').id)
          else
            url = admin_user_receipts_path(@user)
          end
        else
          url = admin_user_receipts_path(@user,'remote-state': assetables_path(assetable_type: @receipt.class.model_name.i18n_key.to_s, assetable_id: @receipt.id) )
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
      if (params.dig(:receipt, :event).present? ? @receipt.send("#{params.dig(:receipt, :event)}!") : @receipt.save)
        format.html { redirect_to admin_user_receipts_path(@user), notice: 'Receipt was successfully updated.' }
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
  # GET /admin/receipts/receipt_barchart
  #
  # This method is used in admin dashboard
  #
  def receipt_barchart
    @data = DashboardData::AdminDataProvider.receipt_block(params[:payments])
    @dataset = get_dataset(@data)
  end
  #
  # GET /admin/receipts/receipt_linechart
  #
  # This method is used in admin dashboard
  #
  def receipt_linechart
    @data = DashboardData::AdminDataProvider.receipt_frequency
    @dataset = get_dataset_linechart(@data)
  end
  #
  # GET /admin/receipts/receipt_piechart
  #
  # This method is used in admin dashboard
  #
  def receipt_piechart
    @data = DashboardData::AdminDataProvider.receipt_piechart
  end

  private

  def set_user
    @user = User.where(_id: params[:user_id]).first
    redirect_to dashboard_path, alert: 'User Not found', status: 404 if @user.blank?
  end

  def set_receipt
    @receipt = Receipt.where(_id: params[:id]).first
    redirect_to dashboard_path, alert: 'Receipt Not found', status: 404 if @receipt.blank?
  end

  def get_dataset(out)
    statuses = Receipt::STATUSES
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
      dataset << { label: status,
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
      dataset << { label: payment_mode,
                    borderColor: '#ffffff',
                    borderWidth: 1,
                    data: d
                  }
    end
    dataset
  end
end
