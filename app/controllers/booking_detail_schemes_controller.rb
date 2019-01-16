class BookingDetailSchemesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_booking_detail
  before_action :set_project_unit
  before_action :set_scheme, except: [:index, :export, :new, :create]
  before_action :authorize_resource
  around_action :apply_policy_scope, only: [:index]
  layout :set_layout

  def index
    @schemes = BookingDetailScheme.build_criteria params
    @schemes = @schemes.paginate(page: params[:page] || 1, per_page: params[:per_page])
    respond_to do |format|
      format.json { render json: @schemes }
      format.html {}
    end
  end

  def show
    @scheme = BookingDetailScheme.find(params[:id])
    render layout: false
  end

  def new
    booking_detail_scheme = if @booking_detail.status == "negotiation_failed"
      @booking_detail.booking_detail_schemes.where(status: "negotiation_failed").desc(:created_at).first
    else
      @booking_detail.booking_detail_scheme
    end

    @scheme = BookingDetailScheme.new(
      derived_from_scheme_id: booking_detail_scheme.derived_from_scheme_id,
      booking_detail_id: @booking_detail.id,
      booking_portal_client_id: current_user.booking_portal_client_id,
      payment_adjustments: booking_detail_scheme.payment_adjustments.collect(&:clone),
      created_by_id: current_user.id,
      created_by_user: true
    )
    render layout: false
  end

  def create
    @scheme = BookingDetailScheme.new(created_by: current_user, booking_portal_client_id: current_user.booking_portal_client_id)
    @scheme.created_by_user = true
    modify_params
    @scheme.assign_attributes(permitted_attributes(@scheme))
    respond_to do |format|
      if @scheme.save
        format.html { redirect_to request.referrer, notice: 'Scheme registered successfully and sent for approval.' }
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
        format.html { redirect_to request.referrer, notice: 'Scheme was successfully updated.' }
      else
        format.html { render :edit }
        format.json { render json: @scheme.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_scheme
    @scheme = if @booking_detail.present?
      @booking_detail.booking_detail_schemes.find(params[:id])
    else
      BookingDetailScheme.where(project_unit_id: @project_unit.id).find(params[:id])
    end
  end

  def set_booking_detail
    @booking_detail = BookingDetail.find(params[:booking_detail_id]) if params[:booking_detail_id].present?
  end

  def set_project_unit
    @project_unit = ProjectUnit.find(params[:project_unit_id]) if params[:project_unit_id].present?
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
      project_unit_id = @project_unit.id if @project_unit.present?
      project_unit_id = @booking_detail.project_unit.id if @booking_detail.present? && project_unit_id.blank?
      authorize BookingDetailScheme.new(created_by: current_user, project_unit_id: project_unit_id)
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