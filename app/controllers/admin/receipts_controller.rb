class Admin::ReceiptsController < AdminController
  include ReceiptsConcern
  before_action :set_user, except: %w[index show export resend_success edit_token_number update_token_number]
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
    @receipt = Receipt.new(user: @user, creator: current_user)
    @receipt.assign_attributes(permitted_attributes([:admin, @receipt]))
    @receipt.account ||= selected_account
    @receipt.payment_gateway ||= current_client.payment_gateway if @receipt.payment_mode == 'online'

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
    respond_to do |format|
      if @receipt.update(permitted_attributes([:admin, @receipt]))
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
