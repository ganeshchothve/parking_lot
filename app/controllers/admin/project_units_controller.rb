class Admin::ProjectUnitsController < AdminController
  before_action :authenticate_user!
  before_action :set_project_unit, except: [:index]
  before_action :authorize_resource
  around_action :apply_policy_scope, only: :index
  include ApplicationHelper
  layout :set_layout

  def index
    @project_units = ProjectUnit.build_criteria(params).paginate(page: params[:page] || 1, per_page: 15)
    respond_to do |format|
      if params[:ds].to_s == 'true'
        format.json { render json: @project_units.collect{|pu| {id: pu.id, name: "#{pu.project_tower_name} | #{pu.name} | #{pu.bedrooms}BHK | #{pu.carpet} Sq.Ft. | #{number_to_indian_currency(pu.booking_price.round)}"}} }
        # format.json { render json: @project_units.collect{|pu| {id: pu.id, name: "Tower: #{pu.project_tower_name} Beds: #{pu.bedrooms} Floor: #{pu.floor} Name: #{pu.name} - Booking Amount: Rs. #{pu.booking_price}"}} }
        format.html {}
      else
        format.json { render json: @project_units }
        format.html {}
      end
    end
  end

  def update
    respond_to do |format|
      if @project_unit.update(permitted_attributes(@project_unit))
        format.html { redirect_to admin_project_units_path, notice: 'Unit successfully updated.' }
      else
        format.html { render :edit }
        format.json { render json: @project_unit.errors, status: :unprocessable_entity }
      end
    end
  end

  private
  def set_project_unit
    @project_unit = ProjectUnit.find(params[:id])
  end

  def authorize_resource
    if params[:action] == "index"
      authorize ProjectUnit
    elsif params[:action] == "new" || params[:action] == "create"
      authorize ProjectUnit.new
    else
      authorize @project_unit
    end
  end

  def apply_policy_scope
    custom_scope = User.all.criteria
    if current_user.role == 'channel_partner'
      custom_scope = custom_scope.where(channel_partner_id: current_user.id).where(role: 'user')
    end
    User.with_scope(policy_scope(custom_scope)) do
      yield
    end
  end
end
