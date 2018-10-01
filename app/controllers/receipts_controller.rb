class ReceiptsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user
  before_action :set_receipt, except: [:index, :export, :new, :create, :direct]
  before_action :set_project_unit
  before_action :authorize_resource
  around_action :apply_policy_scope, only: [:index, :export]

  layout :set_layout

  def index
    @receipts = Receipt.build_criteria params
    @receipts = @receipts.paginate(page: params[:page] || 1, per_page: 15)
  end

  def export
    if Rails.env.development?
      ReceiptExportWorker.new.perform(current_user.id.to_s, params[:fltrs])
    else
      ReceiptExportWorker.perform_async(current_user.id.to_s, params[:fltrs].as_json)
    end
    flash[:notice] = 'Your export has been scheduled and will be emailed to you in some time'
    redirect_to admin_receipts_path(fltrs: params[:fltrs].as_json)
  end

  def resend_success
    user = @receipt.user
    if user.booking_portal_client.email_enabled?
      Email.create!({
        booking_portal_client_id: user.booking_portal_client_id,
        email_template_id:Template::EmailTemplate.find_by(name: "receipt_success").id,
        recipients: [@receipt.user],
        cc_recipients: (user.manager_id.present? ? [user.manager] : []),
        triggered_by_id: @receipt.id,
        triggered_by_type: @receipt.class.to_s
      })
    end
    redirect_to (request.referrer.present? ? request.referrer : dashboard_path)
  end

  def show
    @receipt = Receipt.find(params[:id])
    authorize @receipt
  end

  def new
    if params[:project_unit_id].blank? && current_user.buyer?
      flash[:notice] = "Please Select Apartment before making payment"
      redirect_to(receipts_path)
      return
    end
    if params[:project_unit_id].present?
      project_unit = ProjectUnit.find(params[:project_unit_id])
      @receipt = Receipt.new(creator: current_user, project_unit_id: project_unit.id, user_id: @user, total_amount: (project_unit.status == "hold" ? project_unit.blocking_amount : project_unit.pending_balance))
    else
      @receipt = Receipt.new(creator: current_user, user_id: @user, payment_mode: 'cheque', total_amount: current_client.blocking_amount)
    end
    authorize @receipt
    render layout: false
  end

  def direct
    @receipt = Receipt.new(creator: current_user, user_id: @user, payment_mode: (current_user.buyer? ? 'online' : 'cheque'), total_amount: current_client.blocking_amount)
    authorize @receipt
    render layout: false
  end

  def create
    base_params = {user: @user}
    if params[:receipt][:project_unit_id].present?
      project_unit = ProjectUnit.find(params[:receipt][:project_unit_id])
      base_params.merge!({project_unit_id: project_unit.id})
    end
    @receipt = Receipt.new base_params
    @receipt.creator = current_user
    @receipt.assign_attributes(permitted_attributes(@receipt))
    if @receipt.payment_mode == "online"
      @receipt.payment_gateway = current_client.payment_gateway
    end
    authorize @receipt
    respond_to do |format|
      if @receipt.save
        url = dashboard_path
        if @receipt.payment_mode == 'online'
          if @receipt.payment_gateway_service.present?
            url = @receipt.payment_gateway_service.gateway_url(@receipt.user.get_search(@receipt.project_unit_id).id)
            format.html{ redirect_to url }
            format.json{ render json: {}, location: url }
          else
            flash[:notice] = "We couldn't redirect you to the payment gateway, please try again"
            @receipt.update_attributes(status: "failed")
            url = dashboard_path
          end
        else
          flash[:notice] = "Receipt was successfully updated. Please upload documents"
          if current_user.buyer?
            url = dashboard_path
          else
            url = admin_user_receipts_path(@user)
            url += "?remote-state=#{assetables_path(assetable_type: @receipt.class.model_name.i18n_key.to_s, assetable_id: @receipt.id)}"
          end
        end
        format.json{ render json: @receipt, location: url }
        format.html{ redirect_to url }
      else
        format.json { render json: {errors: @receipt.errors.full_messages}, status: :unprocessable_entity }
        format.html { render 'new' }
      end
    end
  end

  def edit
    render layout: false
  end

  def update
    respond_to do |format|
      if @receipt.update(permitted_attributes(@receipt))
        format.html { redirect_to admin_user_receipts_path(@user), notice: 'Receipt was successfully updated.' }
      else
        format.html { render :edit }
        format.json { render json: {errors: @receipt.errors.full_messages}, status: :unprocessable_entity }
      end
    end
  end

  private
  def set_receipt
    @receipt = Receipt.find(params[:id])
  end

  def set_user
    if current_user.buyer?
      @user = current_user
    else
      @user = (params[:user_id].present? ? User.find(params[:user_id]) : nil)
    end
  end

  def set_project_unit
    @project_unit = if params[:project_unit_id].present?
      ProjectUnit.find(params[:project_unit_id])
    elsif @receipt.present?
      @receipt.project_unit
    end
  end

  def authorize_resource
    if params[:action] == "index" || params[:action] == 'export'
      authorize Receipt
    elsif params[:action] == "new" || params[:action] == "create" || params[:action] == "direct"
      authorize Receipt.new(user_id: @user.id)
    else
      authorize @receipt
    end
  end

  def apply_policy_scope
    custom_scope = Receipt.where(Receipt.user_based_scope(current_user, params))
    Receipt.with_scope(policy_scope(custom_scope)) do
      yield
    end
  end
end
