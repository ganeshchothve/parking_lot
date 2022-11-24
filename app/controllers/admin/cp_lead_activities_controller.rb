class Admin::CpLeadActivitiesController < AdminController
  before_action :authenticate_user!
  before_action :set_cp_lead_activity, except: %i[index]
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
      # TODO : : Still time of QA not checking
      if true#validity_check?
        @cp_lead_activity.assign_attributes(permitted_attributes([current_user_role_group, @cp_lead_activity]))
        if @cp_lead_activity.save
          format.html { redirect_to request.referrer || admin_cp_lead_activities_path, notice: I18n.t("controller.cp_lead_activities.notice.updated") }
          format.json { render json: @cp_lead_activity }
        else
          format.html { render :edit }
          format.json { render json: { errors: @cp_lead_activity.errors.full_messages.uniq }, status: :unprocessable_entity }
        end
      else
        format.html { render :edit }
        format.json { render json: { errors:  I18n.t("controller.cp_lead_activities.errors.cannot_be_updated", name: "#{@cp_lead_activity.lead.active_cp_lead_activities.first.try(:user).try(:name)}") }, status: :unprocessable_entity }
      end
    end
  end

  def show
    @notes = FetchLeadData.fetch_notes(@cp_lead_activity.lead.lead_id, @cp_lead_activity.lead.user.booking_portal_client)
  end

  def extend_validity
    render layout: false
  end

  def update_extension
    respond_to do |format|
      if validity_check?
        extension_date = get_extension_date
        params[:cp_lead_activity][:expiry_date] = extension_date
        @cp_lead_activity.assign_attributes(permitted_attributes([current_user_role_group, @cp_lead_activity]))
        if @cp_lead_activity.save
          format.html { redirect_to request.referrer || admin_cp_lead_activities_path, notice: I18n.t("controller.cp_lead_activities.notice.updated") }
          format.json { render json: @cp_lead_activity }
        else
          format.html { render :extend_validity }
          format.json { render json: { errors: @cp_lead_activity.errors.full_messages.uniq }, status: :unprocessable_entity }
        end
      else
        format.html { render :extend_validity }
        format.json { render json: { errors:  I18n.t("controller.cp_lead_activities.errors.cannot_be_updated", name: "#{@cp_lead_activity.lead.active_cp_lead_activities.first.try(:user).try(:name)}") }, status: :unprocessable_entity }
      end
    end
  end

  def accompanied_credit
    render layout: false
  end

  def update_accompanied_credit
    respond_to do |format|
      if validity_check?
        extension_date = get_extension_date
        params[:cp_lead_activity][:expiry_date] = extension_date
        params[:cp_lead_activity][:count_status] = 'accompanied_count_to_cp'
        @cp_lead_activity.assign_attributes(permitted_attributes([current_user_role_group, @cp_lead_activity]))
        if @cp_lead_activity.save
          format.html { redirect_to request.referrer || admin_cp_lead_activities_path, notice: I18n.t("controller.cp_lead_activities.notice.updated") }
          format.json { render json: @cp_lead_activity }
        else
          format.html { render :edit }
          format.json { render json: { errors: @cp_lead_activity.errors.full_messages.uniq }, status: :unprocessable_entity }
        end
      else
        format.html { render :extend_validity }
        format.json { render json: { errors:  I18n.t("controller.cp_lead_activities.errors.cannot_be_updated", name: "#{@cp_lead_activity.lead.active_cp_lead_activities.first.try(:user).try(:name)}") }, status: :unprocessable_entity }
      end
    end
  end

  private

  def get_extension_date
    if params[:cp_lead_activity][:sitevisit_date].present?
      extention_date = (Time.zone.parse(params[:cp_lead_activity][:sitevisit_date]) + params[:validity_period].to_i.days)
    else
      extention_date = (@cp_lead_activity.expiry_date + params[:validity_period].to_i.days)
    end
    extention_date = Date.current + params[:validity_period].to_i.days if extention_date < Date.current
    extention_date.strftime('%d/%m/%Y')
  end

  def validity_check?
    @cp_lead_activity.lead.active_cp_lead_activities.blank?
  end

  def set_cp_lead_activity
    @cp_lead_activity = CpLeadActivity.where(CpLeadActivity.user_based_scope(current_user, params)).where(id: params[:id]).first
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
