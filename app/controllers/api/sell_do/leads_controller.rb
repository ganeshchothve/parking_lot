# consumes workflow api for leads from sell.do
class Api::SellDo::LeadsController < Api::SellDoController
  before_action :set_user, except: [:site_visit_updated]
  before_action :set_crm, :set_lead, :set_site_visit, only: [:site_visit_updated]

  def lead_created
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

  def site_visit_updated
    respond_to do |format|
      @site_visit.assign_attributes(site_visit_permitted_attributes)
      if @site_visit.save
        format.json { render json: @site_visit }
      else
        format.json { render json: {errors: @site_visit.errors.full_messages}, status: 200 }
      end
    end
  end

  private

  def set_crm
    @crm = Crm::Base.where(domain: ENV_CONFIG.dig(:selldo, :base_url)).first
    render json: { errors: ["Sell.do CRM integration not available"] } and return unless @crm
  end

  def set_lead
    @lead = Lead.where("third_party_references.crm_id": @crm.id, "third_party_references.reference_id": params[:lead_id]).first
    render json: { errors: ["Lead with lead_id '#{params[:lead_id]}' not found"] } and return unless @lead
    @user = @lead.user
  end

  def set_site_visit
    if params.dig("payload", "_id").present?
      @site_visit = @lead.site_visits.where("third_party_references.crm_id": @crm.id, "third_party_references.reference_id": params.dig("payload", "_id")).first
      render json: { errors: ["SiteVisit with id '#{params.dig("payload", "_id")}' not found"] } and return unless @site_visit
    else
      render json: { errors: ["SiteVisit id is missing in params"] } and return
    end
  end

  def site_visit_permitted_attributes
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
        @user = User.new(booking_portal_client_id: current_client.id, email: params[:lead][:email], phone: phone, first_name: params[:lead][:first_name], last_name: params[:lead][:last_name], lead_id: params[:lead_id])
        @user.first_name = "Customer" if @user.first_name.blank?
        @user.last_name = '' if @user.last_name.nil?
        @user[:skip_email_confirmation] = true
      end
    else
      respond_to do |format|
        format.json { render json: {} and return }
      end
    end
  end
end
