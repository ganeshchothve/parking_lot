class ReceiptsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user
  before_action :set_project_unit
  before_action :set_receipt, except: [:index, :export, :new, :create]
  before_action :authorize_resource
  around_action :apply_policy_scope, only: [:index, :export]

  layout :set_layout

  def index
    @receipts = Receipt.build_criteria params
    @receipts = @receipts.paginate(page: params[:page] || 1, per_page: 15)
  end

  def export
    if Rails.env.development?
      ReceiptExportWorker.new.perform(current_user.email)
    else
      ReceiptExportWorker.perform_async(current_user.email)
    end
    flash[:notice] = 'Your export has been scheduled and will be emailed to you in some time'
    redirect_to admin_users_path
  end

  def show
    @receipt = Receipt.find(params[:id])
    authorize @receipt
  end

  def new
    if params[:project_unit_id].blank? && current_user.role?('user')
      redirect_to(receipts_path)
      return
    end
    if params[:project_unit_id].present?
      project_unit = ProjectUnit.find(params[:project_unit_id])
      @receipt = Receipt.new(creator: current_user, project_unit_id: project_unit.id, user_id: @user, total_amount: project_unit.pending_balance, payment_type: 'booking')
    else
      @receipt = Receipt.new(creator: current_user, user_id: @user, payment_mode: 'cheque', payment_type: 'blocking')
    end
    authorize @receipt
  end

  def create
    base_params = {user: @user, reference_project_unit_id: params[:receipt][:reference_project_unit_id]}
    if params[:receipt][:project_unit_id].present?
      project_unit = ProjectUnit.find(params[:receipt][:project_unit_id])
      base_params.merge!({project_unit_id: project_unit.id, reference_project_unit_id: project_unit.id})
    end
    if project_unit.present?
      if ['blocked', 'booked_tentative'].include?(project_unit.status)
        base_params[:payment_type] = 'booking'
      end
    else
      base_params[:payment_type] = 'blocking'
    end
    @receipt = Receipt.new base_params
    @receipt.creator = current_user
    @receipt.assign_attributes(permitted_attributes(@receipt))
    @receipt.receipt_id = Receipt.generate_receipt_id
    @receipt.payment_gateway = 'CCAvenue'
    authorize @receipt
    respond_to do |format|
      if @receipt.save
        format.html {
          if @receipt.payment_mode == 'online'
            if @receipt.payment_gateway_service.present?
              redirect_to @receipt.payment_gateway_service.gateway_url
            else
              flash[:notice] = "We couldn't redirect you to the payment gateway, please try again"
              @receipt.set(status: "failed")
              redirect_to dashboard_path
            end
          else
            redirect_to current_user.role?('user') ? root_path : admin_user_receipts_path(@user)
          end
        }
      else
        format.html { render 'new' }
      end
    end
  end

  def edit
  end

  def update
    respond_to do |format|
      if @receipt.update(permitted_attributes(@receipt))
        format.html { redirect_to admin_user_receipts_path(@user), notice: 'Receipt was successfully updated.' }
      else
        format.html { render :edit }
        format.json { render json: @receipt.errors, status: :unprocessable_entity }
      end
    end
  end

  private
  def set_receipt
    @receipt = Receipt.find(params[:id])
  end

  def set_user
    if current_user.role?("user")
      @user = current_user
    else
      @user = (params[:user_id].present? ? User.find(params[:user_id]) : nil)
    end
  end

  def set_project_unit
    @project_unit = (params[:project_unit_id].present? ? ProjectUnit.find(params[:project_unit_id]) : nil)
  end

  def authorize_resource
    if params[:action] == "index" || params[:action] == 'export'
      authorize Receipt
    elsif params[:action] == "new" || params[:action] == "create"
      authorize Receipt.new(user_id: @user.id)
    else
      authorize @receipt
    end
  end

  def apply_policy_scope
    custom_scope = Receipt.all.criteria
    if current_user.role?('admin') || current_user.role?('crm')
      if params[:user_id].present?
        custom_scope = custom_scope.where(user_id: params[:user_id])
      end
    elsif current_user.role?('channel_partner')
      if params[:user_id].present?
        custom_scope = custom_scope.where(user_id: params[:user_id])
      else
        custom_scope = custom_scope.where(user_id: current_user.id)
      end
    else
      custom_scope = custom_scope.where(user_id: current_user.id)
    end
    Receipt.with_scope(policy_scope(custom_scope)) do
      yield
    end
  end
end
