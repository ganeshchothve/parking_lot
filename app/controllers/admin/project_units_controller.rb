class Admin::ProjectUnitsController < AdminController
  before_action :authenticate_user!
  before_action :set_project_unit, except: [:index, :export, :mis_report]
  before_action :authorize_resource
  around_action :apply_policy_scope, only: :index
  include ApplicationHelper
  layout :set_layout

  def index
    @project_units = ProjectUnit.build_criteria(params).paginate(page: params[:page] || 1, per_page: 15)
    respond_to do |format|
      if params[:ds].to_s == 'true'
        format.json { render json: @project_units.collect{|pu| {id: pu.id, name: pu.ds_name }} }
        format.html {}
      else
        format.json { render json: @project_units }
        format.html {}
      end
    end
  end

  def show
    respond_to do |format|
      format.json { render json: @project_unit }
    end
  end

  def print
    @user = @project_unit.user
  end

  def edit
    render layout: false
  end

  def update
    parameters = permitted_attributes(@project_unit)
    respond_to do |format|
      if @project_unit.update(parameters)
        format.html { redirect_to admin_project_units_path, notice: 'Unit successfully updated.' }
      else
        format.html { render :edit }
        format.json { render json: {errors: @project_unit.errors.full_messages}, status: :unprocessable_entity }
      end
    end
  end

  def export
    if Rails.env.development?
      ProjectUnitExportWorker.new.perform(current_user.id.to_s)
    else
      ProjectUnitExportWorker.perform_async(current_user.id.to_s)
    end
    flash[:notice] = 'Your export has been scheduled and will be emailed to you in some time'
    redirect_to admin_project_units_path
  end

  def mis_report
    if Rails.env.development?
      ProjectUnitMisReportWorker.new.perform(current_user.id.to_s)
    else
      ProjectUnitMisReportWorker.perform_async(current_user.id.to_s)
    end
    flash[:notice] = 'Your mis-report has been scheduled and will be emailed to you in some time'
    redirect_to admin_project_units_path
  end

  private
  def set_project_unit
    @project_unit = ProjectUnit.find(params[:id])
  end

  def authorize_resource
    if params[:action] == "index"
      if params[:ds].to_s == "true"
        authorize(ProjectUnit, :ds?)
      else
        authorize ProjectUnit
      end
    elsif params[:action] == "export" || params[:action] == "mis_report"
      authorize ProjectUnit
    elsif params[:action] == "new" || params[:action] == "create"
      authorize ProjectUnit.new
    else
      authorize @project_unit
    end
  end

  def apply_policy_scope
    custom_project_unit_scope = ProjectUnit.all.criteria
    if current_user.role == "channel_partner"
      custom_project_unit_scope = custom_project_unit_scope.or([{status: "available"}, {status: {"$in": ["blocked", "booked_tentative", "booked_confirmed"]}, user_id: {"$in": User.where(referenced_manager_ids: current_user.id).distinct(:id)}}])
    elsif current_user.buyer?
      custom_project_unit_scope = custom_project_unit_scope.or([{status: {"$in": ProjectUnit.user_based_available_statuses(current_user)}}, {status: {"$in": ["blocked", "booked_tentative", "booked_confirmed"]}, user_id: current_user.id }])
    end
    ProjectUnit.with_scope(policy_scope(custom_project_unit_scope)) do
      custom_scope = User.all.criteria
      if current_user.role == 'channel_partner'
        custom_scope = custom_scope.in(referenced_manager_ids: current_user.id).in(role: User.buyer_roles(current_client))
      end
      User.with_scope(policy_scope(custom_scope)) do
        yield
      end
    end
  end
end
