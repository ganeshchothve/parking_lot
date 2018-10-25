class BookingDetailSchemesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_booking_detail
  before_action :set_scheme, except: [:index, :export, :new, :create]
  before_action :authorize_resource
  around_action :apply_policy_scope, only: [:index]
  layout :set_layout

  def index
    @schemes = BookingDetailScheme.build_criteria params
    @schemes = @schemes.paginate(page: params[:page] || 1, per_page: 15)
    respond_to do |format|
      if params[:ds].to_s == 'true'
        format.json { render json: @schemes.collect{|d| {id: d.id, name: d.name}} }
        format.html {}
      else
        format.json { render json: @schemes }
        format.html {}
      end
    end
  end

  def show
    @scheme = BookingDetailScheme.find(params[:id])
    render layout: false
  end

  def new
    scheme = @booking_detail.booking_detail_scheme
    @scheme = BookingDetailScheme.new(
      derived_from_scheme_id: scheme.derived_from_scheme_id,
      booking_detail_id: @booking_detail.id,
      booking_portal_client_id: current_user.booking_portal_client_id,
      cost_sheet_template_id: scheme.cost_sheet_template_id,
      payment_schedule_template_id: scheme.payment_schedule_template_id,
      payment_adjustments: scheme.payment_adjustments.collect(&:clone),
      created_by_id: current_user.id,
      created_by_user: true
    )
    render layout: false
  end

  def create
    @scheme = BookingDetailScheme.new(created_by: current_user, booking_detail_id: @booking_detail.id, booking_portal_client_id: current_user.booking_portal_client_id)
    @scheme.created_by_user = true
    modify_params
    @scheme.assign_attributes(permitted_attributes(@scheme))
    respond_to do |format|
      if @scheme.save
        format.html { redirect_to admin_user_path(@booking_detail.user.id), notice: 'Scheme registered successfully and sent for approval.' }
        format.json { render json: @scheme, status: :created }
      else
        format.html { render :new }
        format.json { render json: {errors: @scheme.errors.full_messages.uniq}, status: :unprocessable_entity }
      end
    end
  end

  def edit
    render layout: false
  end

  def approve_via_email
    @scheme.status = 'approved'
    @scheme.approved_by = current_user
    respond_to do |format|
      if @scheme.save
        format.html { redirect_to admin_user_path(@booking_detail.user.id), notice: 'Scheme was successfully updated.' }
        format.json { render json: @scheme }
      else
        format.html { render :edit }
        format.json { render json: {errors: @scheme.errors.full_messages.uniq}, status: :unprocessable_entity }
      end
    end
  end

  def update
    modify_params
    @scheme.assign_attributes(permitted_attributes(@scheme))
    @scheme.approved_by = current_user if @scheme.event.present? && @scheme.event == 'approved'
    respond_to do |format|
      if @scheme.save
        format.html { redirect_to admin_user_path(@booking_detail.user.id), notice: 'Scheme was successfully updated.' }
      else
        format.html { render :edit }
        format.json { render json: @scheme.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_scheme
    @scheme = @booking_detail.booking_detail_schemes.find(params[:id])
  end

  def set_booking_detail
    @booking_detail = BookingDetail.find(params[:booking_detail_id])
  end

  def modify_params
    if params[:booking_detail_scheme][:payment_adjustments_attributes].present?
      params[:booking_detail_scheme][:payment_adjustments_attributes].each do |key, value|
        if value[:name].blank? || (value[:formula].blank? && value[:absolute_value].blank?)
          params[:booking_detail_scheme][:payment_adjustments_attributes].delete key
        end
      end
    end
  end

  def authorize_resource
    if params[:action] == "index" || params[:action] == 'export'
      authorize BookingDetailScheme
    elsif params[:action] == "new" || params[:action] == "create"
      authorize BookingDetailScheme.new(created_by: current_user, booking_detail_id: @booking_detail.id)
    else
      authorize @scheme
    end
  end

  def apply_policy_scope
    BookingDetailScheme.with_scope(policy_scope(@booking_detail.booking_detail_schemes)) do
      yield
    end
  end
end
