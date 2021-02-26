class Admin::CpLeadActivitiesController < AdminController
  before_action :authenticate_user!
  before_action :set_cp_lead_activity, only: %i[show edit update]
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

  def edit
    render layout: false
  end

  def update
    respond_to do |format|
      if validity_check?
        @cp_lead_activity.assign_attributes(permitted_attributes([current_user_role_group, @cp_lead_activity]))
        if @cp_lead_activity.save
          format.html { redirect_to request.referrer || admin_cp_lead_activities_path, notice: 'Lead Activity updated successfully.' }
          format.json { render json: @cp_lead_activity }
        else
          format.html { render :edit }
          format.json { render json: { errors: @cp_lead_activity.errors.full_messages.uniq }, status: :unprocessable_entity }
        end
      else
        format.html { render :edit }
        format.json { render json: { errors: "Lead validity can not be updated. Lead is active for #{@cp_lead_activity.lead.active_cp_lead_activities.first.try(:user).try(:name)}" }, status: :unprocessable_entity }
      end
    end
  end

  private

  def validity_check?
    @cp_lead_activity.lead.active_cp_lead_activities.blank?
  end

  def set_cp_lead_activity
    @cp_lead_activity = CpLeadActivity.find(params[:id])
  end

  def authorize_resource
    if %w[index].include?(params[:action])
      authorize [current_user_role_group, CpLeadActivity]
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
