class Admin::ProjectUnitsController < ApplicationController
  include ApplicationHelper
  include ProjectUnitConcern
  before_action :set_project_unit, except: [:index, :export, :mis_report]
  before_action :authorize_resource
  around_action :apply_policy_scope, only: :index
  layout :set_layout

  #def edit from ProjectUnitConcern

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
      format.html {}
    end
  end

  def print #both user id pass
    @user = @project_unit.user
  end

  def update
    parameters = permitted_attributes(@project_unit)
    respond_to do |format|
      if @project_unit.update(parameters)
        format.html { redirect_to (admin_project_units_path), notice: 'Unit successfully updated.' }
      else
        format.html { render :edit }
        format.json { render json: {errors: @project_unit.errors.full_messages}, status: :unprocessable_entity }
      end
    end
  end

  def export
    if Rails.env.development?
      ProjectUnitExportWorker.new.perform(current_user.id.to_s, params[:fltrs].as_json)
    else
      ProjectUnitExportWorker.perform_async(current_user.id.to_s, params[:fltrs].as_json)
    end
    flash[:notice] = 'Your export has been scheduled and will be emailed to you in some time'
    redirect_to admin_project_units_path(fltrs: params[:fltrs].as_json)
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

  def send_under_negotiation #both
    ProjectUnitBookingService.new(@project_unit.id).send_for_negotiation
    respond_to do |format|
      format.html { redirect_to admin_user_path(@project_unit.user.id)}
    end
  end

  private


  def authorize_resource
    if params[:action] == "index"
      if params[:ds].to_s == "true"
        authorize([:admin, ProjectUnit], :ds?)
      else
        authorize [:admin, ProjectUnit]
      end
    elsif params[:action] == "export" || params[:action] == "mis_report"
      authorize [:admin, ProjectUnit]
    else
      authorize [:admin, @project_unit]
    end
  end

  def apply_policy_scope
    custom_project_unit_scope = ProjectUnit.all.criteria
    custom_project_unit_scope = custom_project_unit_scope.or([{status: "available"}, {status: {"$in": ProjectUnit.booking_stages}, user_id: {"$in": User.where(referenced_manager_ids: current_user.id).distinct(:id)}}]) if current_user.role == "channel_partner"

    ProjectUnit.with_scope(policy_scope(custom_project_unit_scope)) do
        custom_scope = User.all.criteria
        custom_scope = custom_scope.in(referenced_manager_ids: current_user.id).in(role: User.buyer_roles(current_client)) if current_user.role == 'channel_partner'
        User.with_scope(policy_scope(custom_scope)) do
          yield
        end
    end
  end
end

=begin
class Admin::ProjectUnitsController < ApplicationController
  include ApplicationHelper
  before_action :set_project_unit, except: [:index, :export, :mis_report]
  before_action :authorize_resource
  around_action :apply_policy_scope, only: :index
  layout :set_layout

  def index #admin
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

  def show #admin
    respond_to do |format|
      format.json { render json: @project_unit }
      format.html {}
    end
  end

  def print #both user id pass
    @user = @project_unit.user
  end

  def edit #both
    render layout: false
  end

  def update #both
    parameters = permitted_attributes(@project_unit)
    respond_to do |format|
      if @project_unit.update(parameters)
        format.html { redirect_to (current_user.buyer? ? dashboard_path : admin_project_units_path), notice: 'Unit successfully updated.' }
      else
        format.html { render :edit }
        format.json { render json: {errors: @project_unit.errors.full_messages}, status: :unprocessable_entity }
      end
    end
  end

  def export #admin
    if Rails.env.development?
      ProjectUnitExportWorker.new.perform(current_user.id.to_s, params[:fltrs].as_json)
    else
      ProjectUnitExportWorker.perform_async(current_user.id.to_s, params[:fltrs].as_json)
    end
    flash[:notice] = 'Your export has been scheduled and will be emailed to you in some time'
    redirect_to admin_project_units_path(fltrs: params[:fltrs].as_json)
  end

  def mis_report #admin
    if Rails.env.development?
      ProjectUnitMisReportWorker.new.perform(current_user.id.to_s)
    else
      ProjectUnitMisReportWorker.perform_async(current_user.id.to_s)
    end
    flash[:notice] = 'Your mis-report has been scheduled and will be emailed to you in some time'
    redirect_to admin_project_units_path
  end

  def send_under_negotiation #both
    ProjectUnitBookingService.new(@project_unit.id).send_for_negotiation
    respond_to do |format|
      format.html { redirect_to admin_user_path(@project_unit.user.id)}
    end
  end

  private
  def set_project_unit #both
    @project_unit = ProjectUnit.find(params[:id])
  end

  def authorize_resource
    if params[:action] == "index" #admin
      if params[:ds].to_s == "true"
        authorize(ProjectUnit, :ds?)
      else
        authorize ProjectUnit
      end
    elsif params[:action] == "export" || params[:action] == "mis_report" #admin
      authorize ProjectUnit
    elsif params[:action] == "new" || params[:action] == "create"
      authorize ProjectUnit.new #remove
    else
      authorize @project_unit
    end
  end

  def apply_policy_scope
    custom_project_unit_scope = ProjectUnit.all.criteria #req for both
    if current_user.role == "channel_partner" #admin
      custom_project_unit_scope = custom_project_unit_scope.or([{status: "available"}, {status: {"$in": ProjectUnit.booking_stages}, user_id: {"$in": User.where(referenced_manager_ids: current_user.id).distinct(:id)}}])
    elsif current_user.buyer? #buyer
      custom_project_unit_scope = custom_project_unit_scope.or([{status: {"$in": ProjectUnit.user_based_available_statuses(current_user)}}, {status: {"$in": ProjectUnit.booking_stages}, user_id: current_user.id }])
    end
    ProjectUnit.with_scope(policy_scope(custom_project_unit_scope)) do
      custom_scope = User.all.criteria
      if current_user.role == 'channel_partner' #admin
        custom_scope = custom_scope.in(referenced_manager_ids: current_user.id).in(role: User.buyer_roles(current_client))
      end
      User.with_scope(policy_scope(custom_scope)) do
        yield
      end
    end
  end
end

  

  
=end
