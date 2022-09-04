class Admin::IncentiveSchemesController < AdminController
  before_action :set_incentive_scheme, except: %i[index new create]
  before_action :authorize_resource
  around_action :apply_policy_scope, only: [:index]

  def index
    @incentive_schemes = IncentiveScheme.build_criteria params
    @incentive_schemes = @incentive_schemes.paginate(page: params[:page] || 1, per_page: params[:per_page])
    respond_to do |format|
      format.json { render json: @incentive_schemes }
      format.html {}
    end
  end

  def new
    @incentive_scheme = IncentiveScheme.new(booking_portal_client_id: current_user.booking_portal_client_id)
    ladder = @incentive_scheme.ladders.build(stage: 1)
    authorize [:admin, @incentive_scheme]
    render layout: false
  end

  def create
    @incentive_scheme = IncentiveScheme.new(booking_portal_client_id: current_user.booking_portal_client_id)
    @incentive_scheme.assign_attributes(permitted_attributes([:admin, @incentive_scheme]))
    respond_to do |format|
      if @incentive_scheme.save
        format.html { redirect_to admin_incentive_schemes_path, notice: I18n.t("controller.incentive_schemes.notice.created") }
        format.json { render json: @incentive_scheme, status: :created }
      else
        format.html { render :new }
        format.json { render json: { errors: @incentive_scheme.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end

  def edit
    render layout: false
  end

  def update
    respond_to do |format|
      if @incentive_scheme.update(permitted_attributes([:admin, @incentive_scheme]))
        format.html { redirect_to admin_incentive_schemes_path, notice: I18n.t("controller.incentive_schemes.notice.updated") }
      else
        format.html { render :edit }
        format.json { render json: { errors: @incentive_scheme.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end

  def end_scheme
    if request.get?
      render layout: false
    elsif request.patch?
      respond_to do |format|
        if @incentive_scheme.update(ends_on: params.dig(:incentive_scheme, :ends_on))
          format.html { redirect_to admin_incentive_schemes_path, notice: I18n.t("controller.incentive_schemes.notice.updated") }
        else
          format.html { render :edit }
          format.json { render json: { errors: @incentive_scheme.errors.full_messages.uniq }, status: :unprocessable_entity }
        end
      end
    end
  end

  private

  def set_incentive_scheme
    @incentive_scheme = IncentiveScheme.where(id: params[:id]).first
    redirect_to dashboard_path, alert: I18n.t("controller.incentive_schemes.alert.not_found") unless @incentive_scheme
  end

  def authorize_resource
    if params[:action] == 'index'
      authorize [current_user_role_group, IncentiveScheme]
    elsif params[:action] == 'new' || params[:action] == 'create'
      authorize [current_user_role_group, IncentiveScheme.new(booking_portal_client_id: current_user.booking_portal_client_id)]
    else
      authorize [current_user_role_group, @incentive_scheme]
    end
  end

  def apply_policy_scope
    custom_scope = IncentiveScheme.all.where(IncentiveScheme.user_based_scope(current_user))
    IncentiveScheme.with_scope(policy_scope(custom_scope)) do
      yield
    end
  end
end
