class Admin::ReceiptsController < AdminController
  before_action :set_user, except: %i[index show export resend_success]
  before_action :set_receipt, only: %i[edit update show resend_success]

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
    @receipt = Receipt.new(
      creator: current_user, user_id: @user, payment_mode: 'online'
    )
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
    @receipt.account = selected_account if @receipt.account.nil?
    @receipt.payment_gateway = current_client.payment_gateway if @receipt.payment_mode == 'online'
    authorize([:admin, @receipt])
    respond_to do |format|
      if @receipt.account.blank?
        flash[:alert] = 'We do not have any Account Details for Transaction. Please ask Administrator to add.'
        format.html { render 'new' }
      else
        if @receipt.save
          flash[:notice] = 'Receipt was successfully updated. Please upload documents'
          if @receipt.payment_mode == 'online'
            if @receipt.payment_identifier.blank?
              url = @receipt.payment_gateway_service.gateway_url(@user.get_search(@receipt.project_unit_id).id)
            else
              url = admin_user_receipts_path(@user)
            end
          else
            url = "#{admin_user_receipts_path(@user)}?remote-state=#{assetables_path(assetable_type: @receipt.class.model_name.i18n_key.to_s, assetable_id: @receipt.id)}"
          end
          format.json { render json: @receipt, location: url }
          format.html { redirect_to url }
        else
          format.json { render json: { errors: @receipt.errors.full_messages }, status: :unprocessable_entity }
          format.html { render 'new' }
        end
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
    respond_to do |format|
      if @receipt.update(permitted_attributes([:admin, @receipt]))
        format.html { redirect_to admin_user_receipts_path(@user), notice: 'Receipt was successfully updated.' }
      else
        format.html { render :edit }
        format.json { render json: { errors: @receipt.errors.full_messages }, status: :unprocessable_entity }
      end
    end
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
end
