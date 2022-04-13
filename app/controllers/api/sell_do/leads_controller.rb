# consumes workflow api for leads from sell.do
class Api::SellDo::LeadsController < Api::SellDoController
  before_action :set_crm, :set_project
  before_action :create_or_set_user
  before_action :create_or_set_lead
  before_action :create_or_set_site_visit, only: [:site_visit_created, :site_visit_updated]
  around_action :user_time_zone, only: [:site_visit_created, :site_visit_updated]

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
    Time.use_zone(@lead.user.time_zone) { yield }
  end

  def set_project
    @project = Project.where(selldo_id: params[:project_id]).first
    render json: { errors: ["Project not found"] } and return unless @project
  end

  def set_crm
    @crm = Crm::Base.where(domain: ENV_CONFIG.dig(:selldo, :base_url)).first
    render json: { errors: ["Sell.do CRM integration not available"] } and return unless @crm
  end

  def create_or_set_user
    if (email = params.dig(:lead, :email).presence) || (phone = params.dig(:lead, :phone).presence)
      query = []
      query << { phone: phone } if phone.present?
      query << { email: email } if email.present?
      @user = User.or(query).first
      if @user.blank?
        phone = Phonelib.parse(params[:lead][:phone]).to_s
        @user = User.new(booking_portal_client_id: @project.booking_portal_client_id, email: params[:lead][:email], phone: phone, first_name: params[:lead][:first_name], last_name: params[:lead][:last_name], is_active: false)
        @user.first_name = "Customer" if @user.first_name.blank?
        @user.last_name = '' if @user.last_name.nil?
        @user.skip_confirmation! # TODO: Remove this when customer login needs to be given
        unless @user.save
          respond_to do |format|
            format.json { render json: {errors: @user.errors.full_messages}, status: 200 }
          end
        end
      end
    else
      respond_to do |format|
        format.json { render json: {} and return }
      end
    end
  end

  def create_or_set_lead
    @lead = @user.leads.where("third_party_references.crm_id": @crm.id, "third_party_references.reference_id": params[:lead_id].to_s).first
    if @lead.present?
      update_source_and_sub_source_on_lead
      update_rera_number_on_lead
    end

    unless @lead
      @lead = @user.leads.new(lead_create_attributes)
      render json: { errors: @lead.errors.full_messages.uniq } and return unless @lead.save
    end
  end

  def update_source_and_sub_source_on_lead
    @lead.set(source: params.dig(:payload, :campaign_info, :source)) if params.dig(:payload, :campaign_info, :source).present? && (@lead.source != params.dig(:payload, :campaign_info, :source))

    @lead.set(sub_source: params.dig(:payload, :campaign_info, :sub_source)) if params.dig(:payload, :campaign_info, :sub_source).present? && (@lead.sub_source != params.dig(:payload, :campaign_info, :sub_source))
  end

  def update_rera_number_on_lead
    @lead.set(rera_id: params.dig(:payload, :custom_rera_number)) if params.dig(:payload, :custom_rera_number).present? && @lead.rera_id != params.dig(:payload, :custom_rera_number)
  end

  def create_or_set_site_visit
    if params.dig("payload", "_id").present?
      @site_visit = @lead.site_visits.where("third_party_references.crm_id": @crm.id, "third_party_references.reference_id": params.dig("payload", "_id")).first
      unless @site_visit.present?
        @site_visit = SiteVisit.new(site_visit_attributes)
        render json: { errors: @site_visit.errors.full_messages.uniq } and return unless @site_visit.save
      end
    else
      render json: { errors: ["SiteVisit id is missing in params"] } and return
    end
  end

  def lead_create_attributes
    {
      email: @user.email,
      phone: @user.phone,
      first_name: @user.first_name,
      last_name: @user.last_name,
      project_id: @project.id,
      lead_stage: params.dig(:payload, :stage),
      source: params.dig(:payload, :campaign_info, :source),
      sub_source: params.dig(:payload, :campaign_info, :sub_source),
      rera_id: params.dig(:payload, :custom_rera_number),
      third_party_references_attributes: [{
        crm_id: @crm.id,
        reference_id: params[:lead_id]
      }]
    }
  end

  def lead_update_attributes
    {
      lead_stage: params.dig(:payload, :stage)
    }
  end

  def site_visit_attributes
    {
      lead_id: @lead.id,
      project_id: @lead.project_id,
      user_id: @lead.user_id,
      creator: @crm.user,
      created_by: "crm-#{@crm.id}",
      scheduled_on: (DateTime.parse(params.dig(:payload, :scheduled_on)) rescue nil),
      third_party_references_attributes: [{
        crm_id: @crm.id,
        reference_id: params.dig('payload', '_id')
      }]
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
