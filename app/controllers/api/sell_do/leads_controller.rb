# consumes workflow api for leads from sell.do
class Api::SellDo::LeadsController < Api::SellDoController
  before_action :set_crm, :set_project
  before_action :set_user, only: [:lead_created]
  before_action :set_lead, except: [:lead_created]
  before_action :set_site_visit, only: [:site_visit_updated]

  def lead_created
    respond_to do |format|
      @lead = @user.leads.new(email: @user.email, phone: @user.phone, first_name: @user.first_name, last_name: @user.last_name, project_id: @project.id, third_party_references_attributes: [{crm_id: @crm.id, reference_id: params[:lead_id]}])
      if @lead.save
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
      if params.dig(:payload, :_id).present?
        @site_visit = SiteVisit.new(site_visit_attributes)
        if @site_visit.save
          format.json { render json: @site_visit }
        else
          format.json { render json: {errors: @site_visit.errors.full_messages}, status: 200 }
        end
      else
        format.json { render json: {errors: 'SiteVisit Id is missing from params'}, status: 200 }
      end
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

  def set_project
    @project = Project.where(selldo_id: params[:project_id]).first
    render json: { errors: ["Project not found"] } and return unless @project
  end

  def set_crm
    @crm = Crm::Base.where(domain: ENV_CONFIG.dig(:selldo, :base_url)).first
    render json: { errors: ["Sell.do CRM integration not available"] } and return unless @crm
  end

  def set_lead
    @lead = Lead.where("third_party_references.crm_id": @crm.id, "third_party_references.reference_id": params[:lead_id]).first
    render json: { errors: ["Lead with lead_id '#{params[:lead_id]}' not found"] } and return unless @lead
    @user = @lead.user
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
      scheduled_on: (DateTime.parse(params.dig(:payload, :scheduled_on)) rescue nil),
      third_party_references_attributes: [{
        crm_id: @crm.id,
        reference_id: params.dig('payload', '_id')
      }]
    }
  end

  def set_site_visit
    if params.dig("payload", "_id").present?
      @site_visit = @lead.site_visits.where("third_party_references.crm_id": @crm.id, "third_party_references.reference_id": params.dig("payload", "_id")).first
      render json: { errors: ["SiteVisit with id '#{params.dig("payload", "_id")}' not found"] } and return unless @site_visit
    else
      render json: { errors: ["SiteVisit id is missing in params"] } and return
    end
  end

  def site_visit_update_attributes
    attrs = {status: params.dig(:payload, :status)}
    case params[:event].to_s
    when 'sitevisit_rescheduled'
      attrs[:scheduled_on] = DateTime.parse(params.dig(:payload, :scheduled_on)) rescue nil
    when 'sitevisit_conducted'
      attrs[:conducted_on] = DateTime.parse(params.dig(:payload, :conducted_on)) rescue nil
    end
    attrs
  end

  def set_user
    if params[:lead_id].present?
      @user = User.where(lead_id: params[:lead_id].to_s).first
      if @user.blank?
        phone = Phonelib.parse(params[:lead][:phone]).to_s
        @user = User.new(booking_portal_client_id: @project.booking_portal_client_id, email: params[:lead][:email], phone: phone, first_name: params[:lead][:first_name], last_name: params[:lead][:last_name], lead_id: params[:lead_id])
        @user.first_name = "Customer" if @user.first_name.blank?
        @user.last_name = '' if @user.last_name.nil?
        @user[:skip_email_confirmation] = true
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
end
