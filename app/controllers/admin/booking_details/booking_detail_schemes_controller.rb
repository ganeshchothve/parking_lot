class Admin::BookingDetails::BookingDetailSchemesController < AdminController
  before_action :set_booking_detail
  before_action :set_project_unit
  before_action :set_scheme, except: [:index, :export, :new, :create]
  before_action :authorize_resource
  around_action :apply_policy_scope, only: [:index]
  layout :set_layout

  def index
    @booking_detail_schemes = BookingDetailScheme.build_criteria params
    @booking_detail_schemes = @booking_detail_schemes.paginate(page: params[:page] || 1, per_page: params[:per_page])
    respond_to do |format|
      format.json { render json: @schemes }
      format.html {}
    end
  end

  def show
    @booking_detail_scheme = BookingDetailScheme.find(params[:id])
    render layout: false
  end

  def new
    @scheme = @booking_detail.project_unit.project_tower.default_scheme
        @booking_detail_scheme = BookingDetailScheme.new(
          derived_from_scheme_id: @scheme.id,
          booking_detail_id: @booking_detail.id,
          created_by_id: @booking_detail.user_id,
          booking_portal_client_id: @scheme.booking_portal_client_id,
          cost_sheet_template_id: @scheme.cost_sheet_template_id,
          payment_schedule_template_id: @scheme.payment_schedule_template_id,
          project_unit_id: @booking_detail.project_unit_id
        )
    render layout: false, template: 'booking_detail_schemes/edit'
  end

  def create
    if @booking_detail_scheme == nil
      @booking_detail_scheme = @booking_detail.booking_detail_scheme
      if @booking_detail_scheme.blank?
        @scheme = @booking_detail.project_unit.project_tower.default_scheme
        @booking_detail_scheme = BookingDetailScheme.new(
          derived_from_scheme_id: @scheme.id,
          booking_detail_id: @booking_detail.id,
          created_by_id: @booking_detail.user_id,
          booking_portal_client_id: @scheme.booking_portal_client_id,
          cost_sheet_template_id: @scheme.cost_sheet_template_id,
          payment_schedule_template_id: @scheme.payment_schedule_template_id,
          project_unit_id: @booking_detail.project_unit_id
        )
      end
    end
    @booking_detail_scheme.assign_attributes(permitted_attributes([ current_user_role_group, @booking_detail_scheme]))
    @booking_detail_scheme.payment_adjustments << @booking_detail_scheme.derived_from_scheme.payment_adjustments
    @booking_detail_scheme.event = 'approved' if @booking_detail_scheme.derived_from_scheme.status == 'approved'
    modify_params
    respond_to do |format|
      if @booking_detail_scheme.event.present?
        _action = "#{@booking_detail_scheme.event}!"
        @booking_detail_scheme.event = nil
      else
        _action = 'save'
      end
      if @booking_detail_scheme.send(_action)
        format.html { redirect_to request.referrer || root_path, notice: @booking_detail_scheme.approved? ? t('controller.booking_detail_schemes.scheme_approved') : t('controller.booking_detail_schemes.scheme_under_negotiation') }
        format.json { render json: @booking_detail_scheme, status: :created }
      else
        format.html { render :new }
        format.json { render json: {errors: @booking_detail_scheme.errors.full_messages.uniq}, status: :unprocessable_entity }
      end
    end
  end

  def edit
    render layout: false, template: 'booking_detail_schemes/edit'
  end

  def approve_via_email
    @booking_detail_scheme.event = 'approved'
    @booking_detail_scheme.approved_by = current_user
    respond_to do |format|
      if @booking_detail_scheme.save
        format.html { redirect_to admin_user_path(@booking_detail.user.id), notice: 'Scheme was successfully updated.' }
        format.json { render json: @booking_detail_scheme }
      else
        format.html { render layout: false, template: 'booking_detail_schemes/edit' }
        format.json { render json: {errors: @booking_detail_scheme.errors.full_messages.uniq}, status: :unprocessable_entity }
      end
    end
  end

  def update
    modify_params
    @booking_detail_scheme.assign_attributes(permitted_attributes([:admin, @booking_detail_scheme]))
    @booking_detail_scheme.event = 'draft' if (@booking_detail_scheme.payment_adjustments.present? && @booking_detail_scheme.payment_adjustments.last.new_record?) || @booking_detail_scheme.derived_from_scheme_id_changed?
    @booking_detail_scheme.approved_by = current_user if @booking_detail_scheme.event.present? && @booking_detail_scheme.event == 'approved'
    respond_to do |format|
      if @booking_detail_scheme.event.present?
        _action = "#{@booking_detail_scheme.event}!"
        @booking_detail_scheme.event = nil
      else
        _action = 'save'
      end
      if @booking_detail_scheme.send(_action)
        format.html { redirect_to request.referrer || root_path , notice: @booking_detail_scheme.approved? ? t('controller.booking_detail_schemes.scheme_approved') : t('controller.booking_detail_schemes.scheme_under_negotiation') }
      else
        format.html { render :edit }
        format.json { render json: @booking_detail_scheme.errors, status: :unprocessable_entity }
      end
    end
  end

  private


  def set_booking_detail
    @booking_detail = BookingDetail.where( id: params[:booking_detail_id]).first if params[:booking_detail_id].present?
    redirect_to root_path, alert: t('controller.booking_details.set_booking_detail_missing'), status: 404 if @booking_detail.blank?
  end

  def set_project_unit
    @project_unit = @booking_detail.project_unit
    redirect_to root_path, alert: t('controller.booking_details.set_project_unit_missing'), status: 404 if @project_unit.blank?
  end

  def set_scheme
    @booking_detail_scheme = if @booking_detail.present?
      @booking_detail.booking_detail_schemes.find(params[:id])
    else
      BookingDetailScheme.where(project_unit_id: @project_unit.id).find(params[:id])
    end
  end

  def modify_params
    if params.dig(:booking_detail_scheme, :payment_adjustments_attributes).present?
      params[:booking_detail_scheme] [:event] = 'draft'
      params[:booking_detail_scheme][:payment_adjustments_attributes].each do |key, value|
        if value[:name].blank? || (value[:formula].blank? && value[:absolute_value].blank?)
          params[:booking_detail_scheme][:payment_adjustments_attributes].delete key
        end
      end
    end

  end

  def authorize_resource
    if params[:action] == "index" || params[:action] == 'export'
      authorize [ :admin, BookingDetailScheme]
    elsif params[:action] == "new" || params[:action] == "create"
      project_unit_id = @project_unit.id if @project_unit.present?
      project_unit_id = @booking_detail.project_unit.id if @booking_detail.present? && project_unit_id.blank?
      booking_detail_id = @booking_detail.id
      @scheme = Scheme.where(_id: params.dig(:booking_detail_scheme, :derived_from_scheme_id) ).last
      @scheme = @booking_detail.project_unit.project_tower.default_scheme if @scheme.blank?

      authorize [ :admin, BookingDetailScheme.new(created_by: current_user, project_unit_id: project_unit_id, booking_detail_id: booking_detail_id, derived_from_scheme_id: @scheme.id )]
    else
      authorize [:admin, @booking_detail_scheme]
    end
  end

  def apply_policy_scope
    BookingDetailScheme.with_scope(policy_scope(@booking_detail.booking_detail_schemes)) do
      yield
    end
  end
end
