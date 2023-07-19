class Admin::LeadManagersController < AdminController
  before_action :authenticate_user!
  before_action :set_lead_manager, except: %i[index]
  before_action :authorize_resource
  around_action :apply_policy_scope, only: %i[index]

  def index
    @lead_managers = LeadManager.build_criteria params
    @lead_managers = @lead_managers.paginate(page: params[:page] || 1, per_page: params[:per_page])
    respond_to do |format|
      format.json { render json: @lead_managers }
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
        @lead_manager.assign_attributes(permitted_attributes([current_user_role_group, @lead_manager]))
        if @lead_manager.save
          format.html { redirect_to request.referrer || admin_lead_managers_path, notice: I18n.t("controller.lead_managers.notice.updated") }
          format.json { render json: @lead_manager }
        else
          format.html { render :edit }
          format.json { render json: { errors: @lead_manager.errors.full_messages.uniq }, status: :unprocessable_entity }
        end
      else
        format.html { render :edit }
        format.json { render json: { errors:  I18n.t("controller.lead_managers.errors.cannot_be_updated", name: "#{@lead_manager.lead.active_lead_managers.first.try(:user).try(:name)}") }, status: :unprocessable_entity }
      end
    end
  end

  def show
    @notes = FetchLeadData.fetch_notes(@lead_manager.lead.lead_id, @lead_manager.lead.user.booking_portal_client)
  end

  def extend_validity
    render layout: false
  end

  def update_extension
    respond_to do |format|
      if validity_check?
        extension_date = get_extension_date
        params[:lead_manager][:expiry_date] = extension_date
        @lead_manager.assign_attributes(permitted_attributes([current_user_role_group, @lead_manager]))
        if @lead_manager.save
          format.html { redirect_to request.referrer || admin_lead_managers_path, notice: I18n.t("controller.lead_managers.notice.updated") }
          format.json { render json: @lead_manager }
        else
          format.html { render :extend_validity }
          format.json { render json: { errors: @lead_manager.errors.full_messages.uniq }, status: :unprocessable_entity }
        end
      else
        format.html { render :extend_validity }
        format.json { render json: { errors:  I18n.t("controller.lead_managers.errors.cannot_be_updated", name: "#{@lead_manager.lead.active_lead_managers.first.try(:user).try(:name)}") }, status: :unprocessable_entity }
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
        params[:lead_manager][:expiry_date] = extension_date
        params[:lead_manager][:count_status] = 'accompanied_count_to_cp'
        @lead_manager.assign_attributes(permitted_attributes([current_user_role_group, @lead_manager]))
        if @lead_manager.save
          format.html { redirect_to request.referrer || admin_lead_managers_path, notice: I18n.t("controller.lead_managers.notice.updated") }
          format.json { render json: @lead_manager }
        else
          format.html { render :edit }
          format.json { render json: { errors: @lead_manager.errors.full_messages.uniq }, status: :unprocessable_entity }
        end
      else
        format.html { render :extend_validity }
        format.json { render json: { errors:  I18n.t("controller.lead_managers.errors.cannot_be_updated", name: "#{@lead_manager.lead.active_lead_managers.first.try(:user).try(:name)}") }, status: :unprocessable_entity }
      end
    end
  end

  private

  def get_extension_date
    if params[:lead_manager][:sitevisit_date].present?
      extention_date = (Time.zone.parse(params[:lead_manager][:sitevisit_date]) + params[:validity_period].to_i.days)
    else
      extention_date = (@lead_manager.expiry_date + params[:validity_period].to_i.days)
    end
    extention_date = Date.current + params[:validity_period].to_i.days if extention_date < Date.current
    extention_date.strftime('%d/%m/%Y')
  end

  def validity_check?
    @lead_manager.lead.active_lead_managers.blank?
  end

  def set_lead_manager
    @lead_manager = LeadManager.where(LeadManager.user_based_scope(current_user, params)).where(id: params[:id]).first
  end

  def authorize_resource
    if %w[index].include?(params[:action])
      authorize [current_user_role_group, LeadManager]
    else
      authorize [current_user_role_group, @lead_manager]
    end
  end

  def apply_policy_scope
    custom_scope = LeadManager.where(LeadManager.user_based_scope(current_user, params))
    LeadManager.with_scope(policy_scope(custom_scope)) do
      yield
    end
  end
end
