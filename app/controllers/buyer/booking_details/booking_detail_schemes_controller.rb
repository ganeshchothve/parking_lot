class Buyer::BookingDetails::BookingDetailSchemesController < BuyerController
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
    @scheme ||= self.project_unit.project_tower.default_scheme
    @booking_detail_scheme.assign_attributes(permitted_attributes([:buyer, @booking_detail_scheme]))
    modify_params
    @booking_detail_scheme.approved!
    respond_to do |format|
      if @scheme.save
        format.html { redirect_to request.referrer || root_path, notice: t('controller.booking_detail_schemes.scheme_approved') }
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
    respond_to do |format|
      if @scheme.save
        format.html { redirect_to request.referrer || root_path , notice: t('controller.booking_detail_schemes.scheme_approved') }
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

  def set_project_unit
    @project_unit = @booking_detail.project_unit
    redirect_to root_path, alert: t('controller.booking_details.set_project_unit_missing'), status: 404 if @project_unit.blank?
  end
  def set_booking_detail
    @booking_detail = BookingDetail.where(id: params[:booking_detail_id]).first if params[:booking_detail_id].present?
    redirect_to root_path, alert: t('controller.booking_details.set_booking_detail_missing'), status: 404 if @booking_detail.blank?
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
      authorize [:buyer, BookingDetailScheme]
    elsif params[:action] == "new" || params[:action] == "create"
      @scheme = Scheme.where(_id: params.dig(:booking_detail_scheme, :derived_from_scheme_id) ).last
      @booking_detail_scheme = BookingDetailScheme.new(created_by: current_user, booking_detail_id: @booking_detail, derived_from_scheme_id: @scheme.try(:_id), status: @scheme.try(:status))
      authorize [:buyer, @booking_detail_scheme]
    else
      authorize [:buyer, @scheme]
    end
  end

  def apply_policy_scope
    BookingDetailScheme.with_scope(policy_scope(@booking_detail.booking_detail_schemes)) do
      yield
    end
  end
end
