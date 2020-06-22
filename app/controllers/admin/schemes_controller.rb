class Admin::SchemesController < AdminController
  include SchemesConcern

  before_action :set_project
  before_action :set_scheme, except: %i[index new create]
  before_action :authorize_resource
  around_action :apply_policy_scope, only: [:index]

  layout :set_layout


  def new
    @scheme = Scheme.new(created_by: current_user, booking_portal_client_id: current_user.booking_portal_client_id)
    authorize [:admin, @scheme]
    render layout: false
  end

  def create
    @scheme = Scheme.new(created_by: current_user, booking_portal_client_id: current_user.booking_portal_client_id)
    modify_params
    @scheme.assign_attributes(permitted_attributes([:admin, @scheme]))

    respond_to do |format|
      if @scheme.save
        format.html { redirect_to admin_schemes_path, notice: 'Scheme registered successfully and sent for approval.' }
        format.json { render json: @scheme, status: :created }
      else
        format.html { render :new }
        format.json { render json: { errors: @scheme.errors.full_messages.uniq }, status: :unprocessable_entity }
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
        format.html { redirect_to admin_schemes_path, notice: 'Scheme was successfully updated.' }
        format.json { render json: @scheme }
      else
        format.html { render :edit }
        format.json { render json: { errors: @scheme.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end

  def update
    modify_params
    @scheme.assign_attributes(permitted_attributes([:admin, @scheme]))
    @scheme.approved_by = current_user if @scheme.event.present? && @scheme.event == 'approved' && @scheme.status != 'approved'
    respond_to do |format|
      if @scheme.save
        format.html { redirect_to admin_schemes_path, notice: 'Scheme was successfully updated.' }
      else
        format.html { render :edit }
        format.json { render json: @scheme.errors, status: :unprocessable_entity }
      end
    end
  end

  def payment_adjustments_for_unit
    project_unit = ProjectUnit.find params[:project_unit_id]
    respond_to do |format|
      format.json { render json: @scheme.payment_adjustments.collect { |payment_adjustment| payment_adjustment.as_json.merge(field: payment_adjustment.field.humanize, value: payment_adjustment.value(project_unit)) } }
    end
  end

  def show
    @booking_details = @scheme.booking_details.paginate(page: params[:page] || 1, per_page: params[:per_page])
  end

  private


  def set_scheme
    @scheme = Scheme.find(params[:id])
  end

  def set_project_tower
    @project = ProjectTower.find params[:project_tower_id] if params[:project_tower_id].present?
  end

  def modify_params
    if params[:scheme][:payment_adjustments_attributes].present?
      params[:scheme][:payment_adjustments_attributes].each do |key, value|
        if value[:name].blank? || (value[:formula].blank? && value[:absolute_value].blank?)
          params[:scheme][:payment_adjustments_attributes].delete key
        end
      end
    end
  end
end
