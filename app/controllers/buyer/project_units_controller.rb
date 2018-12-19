class Buyer::ProjectUnitsController < ApplicationController
  include ApplicationHelper
  include ProjectUnitConcern
  before_action :set_project_unit, except: [:index, :export, :mis_report]
  before_action :authorize_resource
  around_action :apply_policy_scope, only: :index
  layout :set_layout

  #def set_project_unit from ProjectUnitConcern

  def print #both user id pass rem
    @user = @project_unit.user
  end

  def update
    parameters = permitted_attributes(@project_unit)
    respond_to do |format|
      if @project_unit.update(parameters)
        format.html { redirect_to (dashboard_path), notice: 'Unit successfully updated.' }
      else
        format.html { render :edit }
        format.json { render json: {errors: @project_unit.errors.full_messages}, status: :unprocessable_entity }
      end
    end
  end

  def send_under_negotiation  #both
    ProjectUnitBookingService.new(@project_unit.id).send_for_negotiation
    respond_to do |format|
      format.html { redirect_to admin_user_path(@project_unit.user.id)}
    end
  end

  private


  def authorize_resource
    authorize [:buyer, @project_unit]
  end

  def apply_policy_scope
    custom_project_unit_scope = ProjectUnit.all.criteria.or([{status: {"$in": ProjectUnit.user_based_available_statuses(current_user)}}, {status: {"$in": ProjectUnit.booking_stages}, user_id: current_user.id }])
    ProjectUnit.with_scope(policy_scope(custom_project_unit_scope)) do
        custom_scope = User.all.criteria
        User.with_scope(policy_scope(custom_scope)) do
          yield
        end
      end
  end
end
