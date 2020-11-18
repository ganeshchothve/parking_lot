class Admin::ProjectUnitsController < AdminController

  before_action :set_project_unit, except: %i[index export unit_configuration_chart inventory_snapshot]
  include ProjectUnitsConcern
  before_action :authorize_resource
  before_action :set_project_unit_scheme, only: %i[show print]
  around_action :apply_policy_scope, only: :index
  layout :set_layout

  # Defined in ProjectUnitsConcern
  # GET /admin/project_units/:id/edit

  #
  # This index action for Admin users where Admin can view all project units.
  #
  # @return [{},{}] records with array of Hashes.
  # GET /admin/project_units
  #
  def index
    @project_units = ProjectUnit.build_criteria(params).paginate(page: params[:page] || 1, per_page: params[:per_page])
    respond_to do |format|
      if params[:ds].to_s == 'true'
        format.json { render json: @project_units.collect { |pu| { id: pu.id, name: pu.ds_name } } }
        format.html {}
      else
        format.json { render json: @project_units }
        format.html {}
      end
    end
  end

  #
  # This print action for Admin users where Admin can print a particular project unit(cost sheet and payment schedule).
  #
  # GET /admin/project_units/:id/print
  #
  def print
    @user = @project_unit.user
  end

  #
  # This update action for Admin users is called after edit.
  #
  # PATCH /admin/project_units/:id
  #
  def update
    parameters = permitted_attributes([:admin, @project_unit])
    respond_to do |format|
      if @project_unit.update(parameters)
        format.html { redirect_to admin_project_units_path, notice: 'Unit successfully updated.' }
      else
        format.html { render :edit }
        format.json { render json: { errors: @project_unit.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  #
  # This export action for Admin users where Admin will get reports.
  #
  # GET /admin/project_units/export
  #
  def export
    if Rails.env.development?
      ProjectUnitExportWorker.new.perform(current_user.id.to_s, params[:fltrs].as_json)
    else
      ProjectUnitExportWorker.perform_async(current_user.id.to_s, params[:fltrs].as_json)
    end
    flash[:notice] = 'Your export has been scheduled and will be emailed to you in some time'
    redirect_to admin_project_units_path(fltrs: params[:fltrs].as_json)
  end

  #
  # GET /admin/project_units/:id/send_under_negotiation
  #
  def send_under_negotiation
    @project_unit.booking_detail.under_negotiation!
    respond_to do |format|
      format.html { redirect_to admin_user_path(@project_unit.user.id) }
    end
  end


  # after the booking_detail_scheme is rejected, project_unit can be released by calling this action. It makes the project unit available and marks booking_detail as cancelled.
  def release_unit
    BookingDetail.where(project_unit_id: @project_unit.id).each do |bd|
      bd.cancel!
    end
    @project_unit.status = 'available'
    respond_to do |format|
      if @project_unit.save
        flash[:notice] = t('controller.project_units.unit_released')
        format.html { redirect_to admin_project_unit_path(@project_unit) }
      else
        format.html { redirect_to admin_project_units_path }
      end

    end
  end

  def doc
    render layout: false
  end
  #
  # GET /admin/project_units/unit_configuration_chart
  #
  # This method is used in admin dashboard
  #
  def unit_configuration_chart
    @data = DashboardData::AdminDataProvider.project_unit_block
    @dataset = get_dataset(@data)
  end

  def inventory_snapshot
    @out = DashboardDataProvider.inventory_snapshot
  end

  def send_cost_sheet_and_payment_schedule
    if @lead
      render json: {notice: t('controller.project_units.send_cost_sheet_and_payment_schedule.success')}, status: :created
      @booking_detail.send_cost_sheet_and_payment_schedule(@lead)
    else
      render json: {alert: t('controller.project_units.send_cost_sheet_and_payment_schedule.failure')}, status: :unprocessable_entity
    end
  end

  private

  # def set_project_unit
  # Defined in ProjectUnitsConcern

  def set_project_unit_scheme
    @scheme = Scheme.where(_id: params[:selected_scheme_id]).first
    @project_unit.scheme = @scheme if @scheme
  end

  def authorize_resource
    if %w[unit_configuration_chart index inventory_snapshot].include?(params[:action])
      if params[:ds].to_s == 'true'
        authorize([:admin, ProjectUnit], :ds?)
      else
        authorize [:admin, ProjectUnit]
      end
    elsif params[:action] == 'export' || params[:action] == 'mis_report'
      authorize [:admin, ProjectUnit]
    else
      authorize [:admin, @project_unit]
    end
  end

  def apply_policy_scope
    custom_project_unit_scope = ProjectUnit.all.criteria
    custom_project_unit_scope = custom_project_unit_scope.or([{ status: 'available' }, { status: { "$in": ProjectUnit.booking_stages }, user_id: { "$in": User.where(referenced_manager_ids: current_user.id).distinct(:id) } }]) if current_user.role == 'channel_partner'

    ProjectUnit.with_scope(policy_scope(custom_project_unit_scope)) do
      custom_scope = User.all.criteria
      custom_scope = custom_scope.in(referenced_manager_ids: current_user.id).in(role: User.buyer_roles(current_client)) if current_user.role == 'channel_partner'
      User.with_scope(policy_scope(custom_scope)) do
        yield
      end
    end
  end

  def get_dataset(out)
    labels= ProjectTower.distinct(:name)
    configurations = ProjectUnit.distinct(:unit_configuration_name)
    dataset = Array.new
    configurations.each do |configuration|
      d = Array.new
      labels.each do |l|
        if out[l.to_sym].present? && out[l.to_sym][configuration.to_sym].present?
          d << (out[l.to_sym][configuration.to_sym])
        else
          d << 0
        end
      end
      dataset << { label: configuration,
                    borderColor: '#ffffff',
                    borderWidth: 1,
                    data: d
                  }
    end
    dataset
  end
end
