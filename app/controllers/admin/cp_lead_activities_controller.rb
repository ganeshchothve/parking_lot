class Admin::CpLeadActivitiesController < AdminController
  before_action :authenticate_user!
  before_action :authorize_resource
  around_action :apply_policy_scope, only: %i[index]

  def index
    @cp_lead_activities = CpLeadActivity.build_criteria params
    @cp_lead_activities = @cp_lead_activities.paginate(page: params[:page] || 1, per_page: params[:per_page])
    respond_to do |format|
      format.json { render json: @cp_lead_activities }
      format.html {}
    end
  end

  private

  def authorize_resource
    if %w[index].include?(params[:action])
      authorize [current_user_role_group, CpLeadActivity]
    elsif params[:action] == 'new' || params[:action] == 'create'
      if params[:role].present?
        authorize [current_user_role_group, CpLeadActivity.new(user: (current_user.role?(:channel_partner) ? current_user : nil))]
      else
        authorize [current_user_role_group, CpLeadActivity.new(user: (current_user.role?(:channel_partner) ? current_user : nil))]
      end
    else
      authorize [current_user_role_group, @cp_lead_activity]
    end
  end

  def apply_policy_scope
    custom_scope = CpLeadActivity.where(CpLeadActivity.user_based_scope(current_user, params))
    CpLeadActivity.with_scope(policy_scope(custom_scope)) do
      yield
    end
  end
end
