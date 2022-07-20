class SearchesController < ApplicationController
  include SearchConcern
  include ReceiptsConcern
  before_action :authenticate_user!
  before_action :set_search, except: [:index, :export, :new, :create, :tower, :three_d]
  before_action :set_lead, except: [:export]
  before_action :set_form_data, only: [:show, :edit]
  before_action :authorize_resource, except: [:checkout, :hold]
  around_action :apply_policy_scope, only: [:index, :export]
  before_action :set_project_unit, only: [:checkout ]
  before_action :set_booking_detail, only: [:hold, :checkout]
  before_action :check_project_unit_hold_status, only: :checkout

  layout :set_layout

  def three_d

  end

  def show
    if @search.project_unit.present? && @search.project_unit.status == 'hold'
      if redirect_to_checkout?
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
    @search = @lead.searches.new(booking_portal_client_id: current_user.booking_portal_client.id)
    set_form_data
    authorize @search
  end

  def create
    @search = @lead.searches.new(booking_portal_client_id: current_user.booking_portal_client.id)
    set_form_data
    @search.assign_attributes(permitted_attributes(@search))

    respond_to do |format|
      if @search.save
        format.html { redirect_to step_lead_search_path(@search, step: @search.step) }
        format.json { render json: {model: @search, location: step_lead_search_path(@search, step: @search.step)} }
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
      location = step_lead_search_path(@search, step: @search.step)
    end
    respond_to do |format|
      if @search.save
        format.html { redirect_to step_lead_search_path(@search, step: @search.step) }
        format.json { render json: @search, location: location }
      else
        format.html { render :edit }
        format.json { render json: @search.errors, status: :unprocessable_entity }
      end
    end
  end

  def hold
    @booking_detail.event = 'hold' if @booking_detail.new_record?
    @booking_detail.assign_attributes( permitted_attributes([ current_user_role_group, @booking_detail]))

    # Has to be done after user is assigned and before status is updated
    authorize [current_user_role_group, @booking_detail]
    respond_to do |format|
      if @booking_detail.save
        if @booking_detail.create_default_scheme
          format.html { redirect_to checkout_lead_search_path(@search) }
        else
          ProjectUnitUnholdWorker.new.perform(@search.project_unit_id)
          format.html { redirect_to dashboard_path, alert: t('controller.searches.hold.scheme_for_channel_partner_not_found') }
        end
      else
        format.html { redirect_to dashboard_path, alert: t('controller.searches.hold.booking_detail_error') }
      end
    end
  end

  def checkout
    authorize [current_user_role_group, @booking_detail]
    @booking_detail_scheme = @booking_detail.booking_detail_schemes.desc(:created_at).last || @booking_detail.booking_detail_schemes.build
    if @booking_detail.save && !@booking_detail.hold?
      if current_user.buyer?
        redirect_to dashboard_path, alert: t('controller.searches.checkout.non_hold_booking')
      else
        redirect_to admin_lead_path(@search.lead_id), alert: t('controller.searches.checkout.non_hold_booking')
      end
    elsif @search.user && @search.user.receipts.where(project_unit_id: @search.project_unit_id, status: "pending", payment_mode: {"$ne": "online"}).present?
      redirect_to admin_lead_path(@search.lead_id), notice: t('controller.searches.checkout.pending_payments')
    else
      # Open checkout page for costsheet selection
    end
  end

  def make_available
    @project_unit = ProjectUnit.find(@search.project_unit_id)
    authorize [current_user_role_group, @project_unit]
    respond_to do |format|
      result = ProjectUnitUnholdWorker.new.perform(@project_unit.id)
      if !(result.is_a?(Hash) && result.has_key?(:errors))
        format.html { redirect_to dashboard_path, notice: 'Booking cancelled' }
        format.json { render json: {project_unit: @project_unit}, status: 200 }
      else
        format.html { redirect_to (request.referer.present? ? request.referer : dashboard_path), alert: result[:errors] }
        format.json { render json: { errors: result[:errors] }, status: 422 }
      end 
    end
  end

  def payment
    @receipt = Receipt.new(creator: @search.user, user: @search.user, payment_mode: 'online', total_amount: current_client.blocking_amount, payment_gateway: current_client.payment_gateway)
    @receipt.account = selected_account(current_client.payment_gateway.underscore ,@search.project_unit)
    if @search.project_unit_id.present?
      @project_unit = ProjectUnit.find(@search.project_unit_id)
      @receipt.total_amount = @project_unit.blocking_amount
      authorize [current_user_role_group, @project_unit]
      unattached_blocking_receipt = @search.lead.unattached_blocking_receipt @search.project_unit.blocking_amount
      if unattached_blocking_receipt.present?
        @receipt = unattached_blocking_receipt
      end
      @receipt.project_unit = @project_unit
    else
      authorize([ current_user_role_group, Receipt.new(user: @search.user)], :new?)
    end

    authorize([current_user_role_group, @receipt], :create?)
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
        redirect_to [current_user_role_group, @receipt.user], notice: 'Unit is booked successfully.'
      end
    else
      redirect_to checkout_lead_search_path(@booking_detail.search)
    end
  end

  def gateway_payment
    @receipt = Receipt.where(:receipt_id => params[:receipt_id]).first
    if @receipt.present?
      render file: "searches/#{@receipt.payment_gateway.underscore}_payment"
    else
      redirect_to home_path(@search.user), notice: t('controller.searches.gateway_payment.receipt_missing')
    end
  end

  private

  def set_search
    @search = Search.find(params[:id])
  end

  def set_project_unit
    @project_unit = @search.project_unit
    if @project_unit.blank?
      @search.set(step: 'towers')
      redirect_to step_lead_search_path(@search, step: @search.step), alert: t('controller.searches.project_unit_missing')
    end
  end

  def set_lead
    if current_user.buyer?
      @lead = current_user.selected_lead
    elsif params[:lead_id].present?
      @lead = Lead.where(id: params[:lead_id]).first
    elsif @search.present? && @search.lead_id.present?
      @lead = @search.lead
    else
      redirect_to dashboard_path and return
    end
  end

  def authorize_resource
    if params[:action] == "index" || params[:action] == 'export' || params[:action] == 'tower'
      authorize Search
    elsif params[:action] == "new" || params[:action] == "create" || params[:action] == 'three_d'
      authorize Search.new(lead_id: @lead.id)
    else
      authorize @search
    end
  end

  def apply_policy_scope
    custom_scope = Search.all.criteria
    if current_user.role?('admin') || current_user.role?('superadmin') || current_user.role?('crm') || current_user.role?('sales') || current_user.role?('cp')
      if params[:lead_id].present?
        custom_scope = custom_scope.where(lead_id: params[:lead_id])
      end
    elsif current_user.role?('channel_partner')
      lead_ids = Lead.in(referenced_manager_ids: current_user.id).distinct(:id)
      custom_scope = custom_scope.in(lead_id: lead_ids)
    else
      custom_scope = custom_scope.where(user_id: current_user.id)
    end
    Search.with_scope(policy_scope(custom_scope)) do
      yield
    end
  end

  def set_form_data
    @data = ProjectUnit.collection.aggregate([{
      '$match' => {'status' => 'available'} },{
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
    if params[:site_visit_id].present?
      @search.site_visit_id = params[:site_visit_id]
    end
    if @search.next_step.present?
      eval("search_for_#{@search.next_step}")
    elsif @search.project_unit_id.present?
      @user_kycs = @lead.user_kycs.paginate(per_page: 100, page: 1)
      @unit = ProjectUnit.find(@search.project_unit_id)
    end
  end

  def set_booking_detail
    @booking_detail = BookingDetail.where(status: {"$in": BookingDetail::BOOKING_STAGES}, project_unit_id: @search.project_unit_id, project_id: @search.project_unit.project_id, user_id: @lead.user_id, lead: @lead).first
    if @booking_detail.blank?
      @booking_detail = BookingDetail.find_or_initialize_by(project_unit_id: @search.project_unit_id, project_id: @search.project_unit.project_id, user_id: @lead.user_id, lead: @lead, status: 'hold', booking_portal_client_id: @lead.booking_portal_client.id)
      if @booking_detail.new_record?
        @booking_detail.assign_attributes(
          base_rate: @search.project_unit.base_rate,
          project_name: @search.project_unit.project_name,
          project_tower_name: @search.project_unit.project_tower_name,
          bedrooms: @search.project_unit.bedrooms,
          bathrooms: @search.project_unit.bathrooms,
          floor_rise: @search.project_unit.floor_rise,
          saleable: @search.project_unit.saleable,
          costs: @search.project_unit.costs,
          data: @search.project_unit.data,
          manager_id: @search.lead_manager_id,
          site_visit_id: @search.site_visit_id
        )
        @booking_detail.search = @search
      end
    end
  end

  def check_project_unit_hold_status
    if @project_unit.held_on.present? && (@project_unit.held_on + @project_unit.holding_minutes.minutes) < Time.now
      ProjectUnitUnholdWorker.new.perform(@project_unit.id)
      redirect_to [:admin, @lead], alert: t('controller.searches.check_project_unit_hold_status', holding_minutes: @project_unit.holding_minutes)
    end
  end

  def redirect_to_checkout?
    booking_detail  = @lead.booking_details.where(search_id: @search.id).first
    booking_detail.present? && (Search::RESTRICTED_STEP.include?(params[:step]) && params[:action] == "show")
  end

end
