class Admin::ProjectUnitsController < AdminController
  include ApplicationHelper
  include ProjectUnitsConcern
  before_action :set_project_unit, except: %i[index export mis_report]
  before_action :authorize_resource
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
  # This show action for Admin users where Admin can view details of a particular project unit.
  #
  # @return [{}] record with array of Hashes.
  # GET /admin/project_units/:id
  #
  def show
    respond_to do |format|
      format.json { render json: @project_unit }
      format.html {}
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
    parameters = permitted_attributes(@project_unit)
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
  # This mis_report action for Admin users where Admin will be mailed the report
  #
  # GET /admin/project_units/mis_report
  #
  def mis_report
    if Rails.env.development?
      ProjectUnitMisReportWorker.new.perform(current_user.id.to_s)
    else
      ProjectUnitMisReportWorker.perform_async(current_user.id.to_s)
    end
    flash[:notice] = 'Your mis-report has been scheduled and will be emailed to you in some time'
    redirect_to admin_project_units_path
  end

  #
  # GET /admin/project_units/:id/send_under_negotiation
  #
  def send_under_negotiation
    ProjectUnitBookingService.new(@project_unit.id).send_for_negotiation
    respond_to do |format|
      format.html { redirect_to admin_user_path(@project_unit.user.id) }
    end
  end

  private

  # def set_project_unit
  # Defined in ProjectUnitsConcern

  def authorize_resource
    if params[:action] == 'index'
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
end
