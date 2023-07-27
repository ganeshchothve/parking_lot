# consumes workflow api for leads from sell.do
class Api::SellDo::LeadsController < Api::SellDoController
  before_action :set_crm, :set_project
  around_action :user_time_zone, only: [:site_visit_created, :site_visit_updated]
  before_action :register_lead, only: [:lead_created, :lead_updated, :site_visit_created, :site_visit_updated]

  def lead_created
    respond_to do |format|
      format.json { render json: @lead }
    end
  rescue => e
    respond_to do |format|
      format.json { render json: { status: 'error', message: e.message }, status: 200 }
    end
  end

  def lead_updated
    respond_to do |format|
      if @lead.update(lead_update_attributes)
        format.json { render json: @lead }
      else
        format.json { render json: {errors: @lead.errors.full_messages.uniq} }
      end
    end
  rescue => e
    respond_to do |format|
      format.json { render json: { status: 'error', message: e.message }, status: 200 }
    end
  end

  def pushed_to_sales
    @user.confirm # also confirm the user in case of a push to sales event
    respond_to do |format|
      if @user.save
        format.json { render json: @user }
      else
        format.json { render json: {errors: @user.errors.full_messages.uniq} }
      end
    end
  rescue => e
    respond_to do |format|
      format.json { render json: { status: 'error', message: e.message }, status: 200 }
    end
  end

  def site_visit_created
    respond_to do |format|
      format.json { render json: @site_visit }
    end
  end

  def site_visit_updated
    respond_to do |format|
      @site_visit.assign_attributes(site_visit_update_attributes)
      if @site_visit.save
        format.json { render json: @site_visit }
      else
        format.json { render json: {errors: @site_visit.errors.full_messages}, status: 200 }
      end
    end
  end

  private

  def user_time_zone
    Time.use_zone(@current_user.time_zone) { yield }
  end

  def set_project
    @project = Project.where(booking_portal_client_id: @current_client.try(:id), selldo_id: params[:project_id]).first
    render json: { errors: [I18n.t("controller.projects.alert.not_found")] } and return unless @project
  end

  def set_crm
    @crm = Crm::Base.where(booking_portal_client_id: @current_client.try(:id), domain: ENV_CONFIG.dig(:selldo, :base_url)).first
    render json: { errors: [I18n.t("controller.crms.errors.not_available")] } and return unless @crm
  end

  def register_lead
    if attrs = format_params
      @errors, @lead_manager, @user, @lead, @site_visit = ::LeadRegistrationService.new(@current_client, @project, @current_user, attrs).execute

      if @errors.present?
        render json: {errors: @errors} and return
      end
    else
      render json: {errors: I18n.t("controller.apis.message.parameters_missing")} and return
    end
  end

  def format_params
    if params[:lead].present?
      attrs = {
        first_name: params.dig(:lead, :first_name),
        last_name: params.dig(:lead, :last_name),
        email: params.dig(:lead, :email),
        phone: params.dig(:lead, :phone),
        project_id: @project.id,
        lead_stage: params.dig(:payload, :stage),
        source: params.dig(:payload, :campaign_info, :source),
        sub_source: params.dig(:payload, :campaign_info, :sub_source),
        booking_portal_client_id: @current_client.id,
        third_party_references_attributes: [{
          crm_id: @crm.id,
          reference_id: params[:lead_id]
        }]
      }

      if params[:event].in?(%w(sitevisit_scheduled sitevisit_conducted sitevisit_rescheduled))
        attrs[:lead] = {
          site_visits_attributes: {
            "0" => {
              scheduled_on: (DateTime.parse(params.dig(:payload, :scheduled_on)) rescue nil),
              creator_id: @crm.user_id,
              created_by: "crm-#{@crm.id}",
              third_party_references_attributes: [{
                crm_id: @crm.id,
                reference_id: params.dig('payload', '_id')
              }]
            }
          }
        }
      end
    end
    attrs
  end

  def lead_update_attributes
    {
      lead_stage: params.dig(:payload, :stage)
    }
  end

  def site_visit_update_attributes
    attrs = {status: params.dig(:payload, :status)}
    case params[:event].to_s
    when 'sitevisit_rescheduled'
      attrs[:scheduled_on] = DateTime.parse(params.dig(:payload, :scheduled_on)) rescue nil
    when 'sitevisit_conducted'
      attrs[:conducted_on] = DateTime.parse(params.dig(:payload, :sv_conducted_on)) rescue nil
    end
    attrs[:conducted_by] = "crm-#{@crm.id}" if attrs[:conducted_on].present?
    attrs
  end
end
