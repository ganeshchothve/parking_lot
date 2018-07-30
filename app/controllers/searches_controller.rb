class SearchesController < ApplicationController
  include SearchConcern
  before_action :authenticate_user!
  before_action :set_search, except: [:index, :export, :new, :create]
  before_action :set_user, except: [:export]
  before_action :set_form_data, only: [:new, :show, :edit]
  before_action :authorize_resource
  around_action :apply_policy_scope, only: [:index, :export]

  layout :set_layout

  def show
    # GENERICTODO: Handle current user to be from a user based route path
    @search = Search.find(params[:id])
    if params[:step].present?
      @search.step = params[:step]
    end
    if @search.next_step.present?
      eval("search_for_#{@search.next_step}")
    elsif @search.project_unit_id.present?
      @user_kycs = @user.user_kycs.paginate(per_page: 100, page: 1)
      @unit = ProjectUnit.find(@search.project_unit_id)
    end
    authorize @search
  end

  def new
    @search = @user.searches.new
    authorize @search
  end

  def create
    @search = @user.searches.new
    @search.assign_attributes(permitted_attributes(@search))

    respond_to do |format|
      if @search.save
        format.html { redirect_to step_user_search_path(@search, step: @search.step) }
      else
        format.html { render :new }
      end
    end
  end

  def export
    if Rails.env.development?
      SearchExportWorker.new.perform(current_user.email)
    else
      SearchExportWorker.perform_async(current_user.email)
    end
    flash[:notice] = 'Your export has been scheduled and will be emailed to you in some time'
    redirect_to admin_searches_path
  end

  def edit
  end

  def update
    respond_to do |format|
      if @search.update(permitted_attributes(@search))
        format.html { redirect_to step_user_search_path(@search, step: @search.step) }
      else
        format.html { render :edit }
        format.json { render json: @search.errors, status: :unprocessable_entity }
      end
    end
  end

  def hold
    @project_unit = ProjectUnit.find(@search.project_unit_id)
    @project_unit.assign_attributes(permitted_attributes(@project_unit))
    @project_unit.user = current_user if @project_unit.user_id.blank?
    authorize @project_unit # Has to be done after user is assigned and before status is updated

    @project_unit.primary_user_kyc_id = @user.user_kyc_ids.first if @project_unit.primary_user_kyc_id.blank?
    @project_unit.status = "hold"
    respond_to do |format|
      if @project_unit.save
        format.html { redirect_to checkout_user_search_path(@search) }
      else
        flash[:notice] = 'We cannot process your request at this time. Please retry'
        format.html { redirect_to dashboard_path }
      end
    end
  end

  def checkout
    @project_unit = ProjectUnit.find(@search.project_unit_id)
    authorize @project_unit
    if @project_unit.status != "hold"
      if current_user.buyer?
        redirect_to dashboard_path and return
      else
        redirect_to (@project_unit.user_id.present? ? admin_user_path(@project_unit.user_id) : dashboard_path) and return
      end
    elsif @project_unit.user_id.present? && @project_unit.user.receipts.where(reference_project_unit_id: @project_unit.id, status: "pending").present?
      flash[:notice] = "We already have collected a payment for this unit from the same customer."
      redirect_to admin_user_path(@project_unit.user_id) and return
    end
  end

  def checkout_via_email
    project_unit = ProjectUnit.find(@search.project_unit_id)
    authorize @project_unit
    if params[:receipt_id].present?
      receipt = current_user.receipts.where(receipt_id: params[:receipt_id]).where(payment_type: 'blocking').first
      if receipt.present? && receipt.project_unit_id.blank? && project_unit.user_based_status(current_user) == 'available' && receipt.reference_project_unit_id.to_s == project_unit.id.to_s
        params[:project_unit] = {status: 'hold', primary_user_kyc_id: current_user.user_kyc_ids.first}
        hold
      else
        flash[:notice] = 'The previously chosen unit may not be available now. You can browse available inventory and block it against the payment done.'
        redirect_to new_search_path
      end
    end
  end

  def make_available
    @project_unit = ProjectUnit.find(@search.project_unit_id)
    authorize @project_unit
    respond_to do |format|
      if @project_unit.update_attributes(permitted_attributes(@project_unit))
        format.html { redirect_to dashboard_path }
        format.json { render json: {project_unit: @project_unit}, status: 200 }
      else
        flash[:notice] = 'Could not update the project unit. Please retry'
        format.html { redirect_to request.referer.present? ? request.referer : dashboard_path }
        format.json { render json: {errors: @project_unit.errors.full_messages.uniq}, status: 422 }
      end
    end
  end

  def payment
    @receipt = Receipt.new(creator: @search.user, user: @search.user, payment_mode: 'online', total_amount: ProjectUnit.blocking_amount, payment_type: 'blocking')

    if @search.project_unit_id
      @project_unit = ProjectUnit.find(@search.project_unit_id)
      authorize @project_unit
      if(@search.user.total_unattached_balance >= ProjectUnit.blocking_amount)
        @receipt = @search.user.unattached_blocking_receipt
      end

      @receipt.project_unit = @project_unit
    else
      authorize(Receipt.new(user: @search.user), :new?)
    end
    if @receipt.payment_type == "blocking"
      @receipt.payment_gateway = 'Razorpay'
    else
      @receipt.payment_gateway = 'Razorpay'
    end
    if @receipt.save
      if @receipt.status == "pending" # if we are just tagging an already successful receipt, we dont need to send the user to payment gateway
        if @receipt.payment_gateway_service.present?
          redirect_to @receipt.payment_gateway_service.gateway_url(@search.id)
        else
          @receipt.update_attributes(status: "failed")
          flash[:notice] = "We couldn't redirect you to the payment gateway, please try again"
          redirect_to dashboard_path
        end
      elsif ['clearance_pending', "success"].include?(@receipt.status)
        redirect_to dashboard_path
      end
    else
      redirect_to checkout_user_search_path(project_unit_id: @project_unit.id)
    end
  end

  def razorpay_payment
    @receipt = Receipt.where(:receipt_id => params[:receipt_id]).first
    @project_unit = ProjectUnit.find(@receipt.project_unit_id) if @receipt.project_unit_id.present?
    if @receipt.present? && @receipt.status == "pending"
      ApplicationLog.log("sent_to_payment_gateway", {
        receipt_id: @receipt.id,
        unit_id: @receipt.project_unit_id,
        user_id: @receipt.user_id
      }, RequestStore.store[:logging])
    else
      redirect_to home_path(@search.user)
    end
  end

  private
  def set_search
    @search = Search.find(params[:id])
  end

  def set_user
    if current_user.buyer?
      @user = current_user
    elsif params[:user_id].present?
      @user = (params[:user_id].present? ? User.find(params[:user_id]) : nil)
    elsif @search.present? && @search.user_id.present?
      @user = @search.user
    else
      redirect_to dashboard_path and return
    end
  end

  def authorize_resource
    if params[:action] == "index" || params[:action] == 'export'
      authorize Search
    elsif params[:action] == "new" || params[:action] == "create"
      authorize Search.new(user_id: @user.id)
    else
      authorize @search
    end
  end

  def apply_policy_scope
    custom_scope = Search.all.criteria
    if current_user.role?('admin') || current_user.role?('crm') || current_user.role?('sales') || current_user.role?('cp')
      if params[:user_id].present?
        custom_scope = custom_scope.where(user_id: params[:user_id])
      end
    elsif current_user.role?('channel_partner')
      user_ids = User.in(referenced_channel_partner_ids: current_user.id).in(role: User.buyer_roles).distinct(:id)
      custom_scope = custom_scope.in(user_id: user_ids)
    else
      custom_scope = custom_scope.where(user_id: current_user.id)
    end
    Search.with_scope(policy_scope(custom_scope)) do
      yield
    end
  end

  def set_form_data
    @data = ProjectUnit.collection.aggregate([{
      "$group": {
        "_id": {
          bedrooms: "$bedrooms"
        },
        agreement_price: {
          "$addToSet": "$agreement_price"
        },
        carpet: {
          "$addToSet": "$carpet"
        }
      }
    },{
      "$sort": {
        "_id.bedrooms": 1
      }
    },{
      "$project": {
        min_agreement_price: {"$min": "$agreement_price"},
        max_agreement_price: {"$max": "$agreement_price"},
        min_carpet: {"$min": "$carpet"},
        max_carpet: {"$max": "$carpet"},
        bedrooms: "$bedrooms"
      }
    }]).to_a
  end
end
