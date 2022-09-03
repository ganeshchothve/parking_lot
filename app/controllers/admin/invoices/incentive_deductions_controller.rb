class Admin::Invoices::IncentiveDeductionsController < AdminController
  before_action :set_invoice
  before_action :set_incentive_deduction, except: [:index, :new, :create]
  before_action :authorize_resource
  around_action :apply_policy_scope, only: [:index]

  def index
    @incentive_deductions = IncentiveDeduction.build_criteria(params).paginate(page: params[:page] || 1, per_page: params[:per_page])
    respond_to do |format|
      format.html { render template: 'admin/incentive_deductions/index' }
    end
  end

  def show
    render layout: false
  end

  def new
    @incentive_deduction = @invoice.build_incentive_deduction(creator: current_user)
    render layout: false
  end

  def create
    @incentive_deduction = @invoice.build_incentive_deduction(creator: current_user)
    @incentive_deduction.assign_attributes(permitted_attributes([current_user_role_group, @incentive_deduction]))
    respond_to do |format|
      if @incentive_deduction.save
        format.json { render json: @incentive_deduction, status: :ok }
      else
        format.json { render json: { errors: @incentive_deduction.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end

  def edit
    render layout: false
  end

  def update
    respond_to do |format|
      if @incentive_deduction.update(permitted_attributes([current_user_role_group, @incentive_deduction]))
        format.json { render json: @incentive_deduction, status: :ok }
      else
        format.json { render json: { errors: @incentive_deduction.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end

  def change_state
    respond_to do |format|
      if @incentive_deduction.update(permitted_attributes([current_user_role_group, @incentive_deduction]))
        format.html { redirect_to request.referer, notice: t("controller.incentive_deductions.status_message.#{@incentive_deduction.status}") }
      else
        format.html { redirect_to request.referer, alert: @incentive_deduction.errors.full_messages.uniq! }
      end
    end
  end

  private

  def set_invoice
    @invoice = Invoice.where(id: params[:invoice_id]).first if params[:invoice_id].present?
  end

  def set_incentive_deduction
    @incentive_deduction = IncentiveDeduction.where(id: params[:id]).first
    redirect_to dashboard_path, alert: I18n.t("controller.errors.not_found", name: "Incentive deduction") unless @incentive_deduction.present?
  end

  def authorize_resource
    if params[:action] == 'index'
      authorize [current_user_role_group, IncentiveDeduction]
    elsif params[:action].in?(%w(new create))
      authorize [current_user_role_group, @invoice.build_incentive_deduction]
    elsif params[:action].in?(%w(edit update))
      authorize [current_user_role_group, @incentive_deduction]
    else
      authorize [current_user_role_group, @incentive_deduction]
    end
  end

  def apply_policy_scope
    custom_scope = IncentiveDeduction.where(IncentiveDeduction.user_based_scope(current_user, params))
    IncentiveDeduction.with_scope(policy_scope(custom_scope)) do
      yield
    end
  end
end
