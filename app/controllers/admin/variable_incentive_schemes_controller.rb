class Admin::VariableIncentiveSchemesController < AdminController
  before_action :set_variable_incentive_scheme, except: %i[index new create vis_details export]
  before_action :get_options, only: %i[show vis_details export]
  before_action :authorize_resource
  around_action :apply_policy_scope, only: [:index, :export]

  def index
    @variable_incentive_schemes = VariableIncentiveScheme.build_criteria params
    @variable_incentive_schemes = @variable_incentive_schemes.paginate(page: params[:page] || 1, per_page: params[:per_page])
    respond_to do |format|
      format.json { render json: @variable_incentive_schemes }
      format.html {}
    end
  end

  def new
    @variable_incentive_scheme = VariableIncentiveScheme.new(created_by: current_user)
    authorize [:admin, @variable_incentive_scheme]
    render layout: false
  end

  def show
  end

  def create
    @variable_incentive_scheme = VariableIncentiveScheme.new(created_by: current_user)
    @variable_incentive_scheme.assign_attributes(permitted_attributes([:admin, @variable_incentive_scheme]))
    respond_to do |format|
      if @variable_incentive_scheme.save
        format.html { redirect_to admin_incentive_schemes_path, notice: 'Incentive Scheme created successfully.' }
        format.json { render json: @variable_incentive_scheme, status: :created }
      else
        format.html { render :new }
        format.json { render json: { errors: @variable_incentive_scheme.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end

  def edit
    render layout: false
  end

  def update
    respond_to do |format|
      @variable_incentive_scheme.approved_by = current_user if params.dig(:variable_incentive_scheme, :event).present? && params.dig(:variable_incentive_scheme, :event) == 'approved' && @variable_incentive_scheme.status != 'approved'
      if @variable_incentive_scheme.update(permitted_attributes([:admin, @variable_incentive_scheme]))
        format.html { redirect_to admin_incentive_schemes_path, notice: 'Incentive Scheme was successfully updated.' }
      else
        format.html { render :edit }
        format.json { render json: { errors: @variable_incentive_scheme.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end

  def end_scheme
    if request.get?
      render layout: false
    elsif request.patch?
      respond_to do |format|
        if @variable_incentive_scheme.update(end_date: params.dig(:variable_incentive_scheme, :end_date))
          format.html { redirect_to admin_variable_incentive_schemes_path, notice: 'Variable Incentive Scheme was successfully updated.' }
        else
          format.html { render :edit }
          format.json { render json: { errors: @variable_incentive_scheme.errors.full_messages.uniq }, status: :unprocessable_entity }
        end
      end
    end
  end

  def vis_details
    @vis_id = params[:id]
    @options.merge!(query: get_query)
    @vis_details = VariableIncentiveSchemeCalculator.vis_details(@options)
    respond_to do |format|
      format.json { render json: @vis_details }
      format.html {}
    end
  end

  def export
    @options.merge!(query: get_query)
    if Rails.env.development?
      VariableIncentiveExportWorker.new.perform(current_user.id.to_s, @options)
    else
      VariableIncentiveExportWorker.perform_async(current_user.id.to_s, @options.as_json)
    end
    flash[:notice] = 'Your export has been scheduled and will be emailed to you in some time'
    filters = params.as_json.slice("user_id", "project_ids", "variable_incentive_scheme_ids", "user_id")
    redirect_to vis_details_admin_variable_incentive_schemes_path(filters)
  end

  private

  def set_variable_incentive_scheme
    @variable_incentive_scheme = VariableIncentiveScheme.where(id: params[:id]).first
    redirect_to dashboard_path, alert: 'Incentive scheme not found' unless @variable_incentive_scheme
  end

  def authorize_resource
    if ['index', 'vis_details', "export"].include?(params[:action])
      authorize [current_user_role_group, VariableIncentiveScheme]
    elsif params[:action] == 'new' || params[:action] == 'create'
      authorize [current_user_role_group, VariableIncentiveScheme.new(created_by: current_user)]
    else
      authorize [current_user_role_group, @variable_incentive_scheme]
    end
  end

  def apply_policy_scope
    custom_scope = VariableIncentiveScheme.all.where(VariableIncentiveScheme.user_based_scope(current_user))
    VariableIncentiveScheme.with_scope(policy_scope(custom_scope)) do
      yield
    end
  end

  def get_query
    query = []
    query << {project_ids: {"$in": params[:project_ids]}} if params[:project_ids].present?
    query << {id: {"$in": params[:variable_incentive_scheme_ids]}} if params[:variable_incentive_scheme_ids].present?
    query
  end

  def get_options
    @options = {}
    params[:variable_incentive_scheme_ids] = [params[:id]] if params[:id].present?
    @options.merge!(user_id: params[:user_id]) if params[:user_id].present?
    @options.merge!(project_ids: params[:project_ids]) if params[:project_ids].present?
    if ["cp_owner", "channel_partner"].include?(current_user.role)
      @options.merge!(user_id: current_user.id.to_s)
    end
  end
end