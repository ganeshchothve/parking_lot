class SearchesController < ApplicationController
  include SearchConcern
  before_action :authenticate_user!
  before_action :set_search, except: [:index, :export, :new, :create, :tower, :three_d]
  before_action :set_user, except: [:export]
  before_action :set_form_data, only: [:show, :edit]
  before_action :authorize_resource
  around_action :apply_policy_scope, only: [:index, :export]

  layout :set_layout

  def three_d

  end

  def show
    if @search.project_unit.present? && @search.project_unit.status == 'hold'
      if @search.user_id == @search.project_unit.user_id
        redirect_to checkout_user_search_path(@search)
      end
    end
    # GENERICTODO: Handle current user to be from a user based route path
  end

  def tower
    @tower = ProjectTower.find(params[:project_tower_id])
    respond_to do |format|
      format.json { render json: @tower.to_json }
    end
  end

  def new
    @search = @user.searches.new
    set_form_data
    authorize @search
  end

  def create
    @search = @user.searches.new
    @search.assign_attributes(permitted_attributes(@search))

    respond_to do |format|
      if @search.save
        format.html { redirect_to step_user_search_path(@search, step: @search.step) }
        format.json { render json: {model: @search, location: step_user_search_path(@search, step: @search.step)} }
      else
        format.html { render :new }
        format.json { render json: {errors: @search.errors.full_messages} }
      end
    end
  end

  def export
    if Rails.env.development?
      SearchExportWorker.new.perform(current_user.id.to_s)
    else
      SearchExportWorker.perform_async(current_user.id.to_s)
    end
    flash[:notice] = 'Your export has been scheduled and will be emailed to you in some time'
    redirect_to admin_searches_path
  end

  def edit
    render layout: false
  end

  def update
    @search.assign_attributes(permitted_attributes(@search))
    location = nil
    if (permitted_attributes(@search).keys.collect{|x| x.to_s} & ['bedrooms', 'agreement_price', 'all_inclusive_price']).present?
      @search.step = 'filter'
      location = step_user_search_path(@search, step: @search.step)
    end
    respond_to do |format|
      if @search.save
        format.html { redirect_to step_user_search_path(@search, step: @search.step) }
        format.json { render json: @search, location: location }
      else
        format.html { render :edit }
        format.json { render json: @search.errors, status: :unprocessable_entity }
      end
    end
  end

  def hold
    @project_unit = ProjectUnit.find(@search.project_unit_id)
    @project_unit.assign_attributes(permitted_attributes(@project_unit))
    @project_unit.user = @user if @project_unit.user_id.blank?
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
    if @search.project_unit_id.blank?
      redirect_to step_user_search_path(@search, step: @search.step)
      return
    end
    @project_unit = ProjectUnit.find(@search.project_unit_id)
    if @project_unit.held_on.present? && (@project_unit.held_on + @project_unit.holding_minutes.minutes) < Time.now
      flash[:notice] = "We've released the unit which was held for #{@project_unit.holding_minutes} minutes. Please re-select the unit and try booking again."
      ProjectUnitUnholdWorker.new.perform(@project_unit.id)
      redirect_to dashboard_path and return
    end
    authorize @project_unit
    if @project_unit.status != "hold"
      if current_user.buyer?
        redirect_to dashboard_path and return
      else
        redirect_to (@project_unit.user_id.present? ? admin_user_path(@project_unit.user_id) : dashboard_path) and return
      end
    elsif @project_unit.user_id.present? && @project_unit.user.receipts.where(project_unit_id: @project_unit.id, status: "pending", payment_mode: {"$ne": "online"}).present?
      flash[:notice] = "We already have collected a payment for this unit from the same customer."
      redirect_to admin_user_path(@project_unit.user_id) and return
    end
  end

  def update_template
    @project_unit = ProjectUnit.find(@search.project_unit_id)
    authorize @project_unit
    respond_to do |format|
      if @project_unit.update_attributes(permitted_attributes(@project_unit))
        format.html { redirect_to checkout_user_search_path(@search) }
        format.json { render json: {project_unit: @project_unit}, status: 200 }
      else
        flash[:notice] = 'Could not update the project unit. Please retry'
        format.html { redirect_to checkout_user_search_path(@search) }
        format.json { render json: {errors: @project_unit.errors.full_messages.uniq}, status: 422 }
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
    @receipt = Receipt.new(creator: @search.user, user: @search.user, payment_mode: 'online', total_amount: current_client.blocking_amount, payment_gateway: current_client.payment_gateway)
    if @search.project_unit_id.present?
      @project_unit = ProjectUnit.find(@search.project_unit_id)
      authorize @project_unit
      unattached_blocking_receipt = @search.user.unattached_blocking_receipt
      if unattached_blocking_receipt.present?
        @receipt = unattached_blocking_receipt
      end
      @receipt.project_unit = @project_unit
    else
      authorize(Receipt.new(user: @search.user), :new?)
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
      else
        redirect_to admin_user_path(@receipt.user)
      end
    else
      redirect_to checkout_user_search_path(project_unit_id: @project_unit.id)
    end
  end

  def razorpay_payment
    @receipt = Receipt.where(:receipt_id => params[:receipt_id]).first
    if @receipt.present? && @receipt.status == "pending"
      @project_unit = ProjectUnit.find(@receipt.project_unit_id) if @receipt.project_unit_id.present?
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
    if params[:action] == "index" || params[:action] == 'export' || params[:action] == 'tower'
      authorize Search
    elsif params[:action] == "new" || params[:action] == "create" || params[:action] == 'three_d'
      authorize Search.new(user_id: @user.id)
    else
      authorize @search
    end
  end

  def apply_policy_scope
    custom_scope = Search.all.criteria
    if current_user.role?('admin') || current_user.role?('superadmin') || current_user.role?('crm') || current_user.role?('sales') || current_user.role?('cp')
      if params[:user_id].present?
        custom_scope = custom_scope.where(user_id: params[:user_id])
      end
    elsif current_user.role?('channel_partner')
      user_ids = User.in(referenced_manager_ids: current_user.id).in(role: User.buyer_roles(current_client)).distinct(:id)
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
        all_inclusive_price: {
          "$addToSet": "$all_inclusive_price"
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
        min_all_inclusive_price: {"$min": "$all_inclusive_price"},
        max_all_inclusive_price: {"$max": "$all_inclusive_price"},
        min_carpet: {"$min": "$carpet"},
        max_carpet: {"$max": "$carpet"},
        bedrooms: "$bedrooms"
      }
    }]).to_a

    if params[:step].present?
      @search.step = params[:step]
    end
    if @search.next_step.present?
      eval("search_for_#{@search.next_step}")
    elsif @search.project_unit_id.present?
      @user_kycs = @user.user_kycs.paginate(per_page: 100, page: 1)
      @unit = ProjectUnit.find(@search.project_unit_id)
    end
  end
end
