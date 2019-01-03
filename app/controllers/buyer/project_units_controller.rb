class Buyer::ProjectUnitsController < BuyerController
  include ApplicationHelper
  include ProjectUnitsConcern
  before_action :set_project_unit, except: %i[index export mis_report]
  before_action :authorize_resource
  around_action :apply_policy_scope, only: :index
  layout :set_layout

  # Defined in ProjectUnitsConcern
  # GET /buyer/project_units/:id/edit

  # This index action for users used to collect and display available project units(for swap requests)
  #
  # @return [{},{}] records with array of Hashes.
  # GET /buyer/project_units
  #
  def index
    @project_units = ProjectUnit.where(status: "available")
    respond_to do |format|
      if params[:ds].to_s == 'true'
        format.json { render json: @project_units.collect { |pu| { id: pu.id, name: pu.ds_name } } }
      else
        format.json { render json: @project_units }
      end
      format.html { redirect_to dashboard_path, notice: 'Only admins can view this page.'}
    end
  end

  #
  # This update action for users is called after edit.
  #
  # PATCH /buyer/project_units/:id"
  #
  def update
    parameters = permitted_attributes(@project_unit)
    respond_to do |format|
      if @project_unit.update(parameters)
        format.html { redirect_to dashboard_path, notice: 'Unit successfully updated.' }
      else
        format.html { render :edit }
        format.json { render json: { errors: @project_unit.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def send_under_negotiation
    ProjectUnitBookingService.new(@project_unit.id).send_for_negotiation
    respond_to do |format|
      format.html { redirect_to buyer_user_path(@project_unit.user.id) }
    end
  end

  private


  # def set_project_unit
  # Defined in ProjectUnitsConcern

  def authorize_resource
    if params[:action] == "index"
      authorize [:buyer, ProjectUnit]
    else
    authorize [:buyer, @project_unit]
    end
  end

  def apply_policy_scope
    custom_project_unit_scope = ProjectUnit.all.criteria.or([{ status: { "$in": ProjectUnit.user_based_available_statuses(current_user) } }, { status: { "$in": ProjectUnit.booking_stages }, user_id: current_user.id }])
    ProjectUnit.with_scope(policy_scope(custom_project_unit_scope)) do
      custom_scope = User.all.criteria
      User.with_scope(policy_scope(custom_scope)) do
        yield
      end
    end
  end
end
