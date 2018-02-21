class Admin::ProjectUnitsController < AdminController
  before_action :authenticate_user!
  before_action :set_project_unit, except: [:index]
  before_action :authorize_resource
  around_action :apply_policy_scope, only: :index

  layout :set_layout

  def index
    @project_units = ProjectUnit.build_criteria(params).paginate(page: params[:page] || 1, per_page: 15)
    respond_to do |format|
      if params[:ds].to_s == 'true'
        format.json { render json: @project_units.collect{|pu| {id: pu.id, name: "#{pu.name} - Booking Amount: Rs. #{pu.booking_price}"}} }
        format.html {}
      else
        format.json { render json: @project_units }
        format.html {}
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
