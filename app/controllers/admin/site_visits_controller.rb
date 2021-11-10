class Admin::SiteVisitsController < AdminController

  before_action :set_lead, except: %w[index show sync_with_selldo]
  before_action :set_site_visit, only: %w[edit update show sync_with_selldo]
  before_action :set_crm_base, only: %w[create sync_with_selldo]
  around_action :user_time_zone, if: :current_user

  #
  # This index action for Admin users where Admin can view all site_visits.
  #
  #
  # @return [{},{}] records with array of Hashes.
  # GET /admin/site_visits
  def index
    authorize([:admin, SiteVisit])
    @site_visits = SiteVisit.where(SiteVisit.user_based_scope(current_user, params))
                       .build_criteria(params)
                       .paginate(page: params[:page] || 1, per_page: params[:per_page])
    respond_to do |format|
      format.json { render json: @site_visits.as_json(methods: [:name]) }
      format.html
    end
  end

  #
  # This new action always create a new site_visit form for user's project unit rerceipt form.
  #
  # GET "/admin/leads/:lead_id/site_visits/new"
  def new
    @site_visit = SiteVisit.new(
      creator: current_user, user: @lead.user, lead: @lead, project_id: @lead.project_id
    )
    authorize([:admin, @site_visit])
    render layout: false
  end

  #
  # This create action always create a new site_visit for user's project unit site_visit form.
  #
  # POST /admin/leads/:lead_id/site_visits
  def create
    @site_visit = SiteVisit.new(user: @lead.user, lead: @lead, creator: current_user, project: @lead.project)
    @site_visit.assign_attributes(permitted_attributes([:admin, @site_visit]))

    selldo_api, api_log = @site_visit.push_in_crm(@crm_base) if @crm_base.present?

    respond_to do |format|
      if selldo_api.blank? || (api_log.present? && api_log.status == 'Success')
        if @site_visit.save
          flash[:notice] = 'Site visit was successfully created'
          url = admin_lead_path(@lead)
          format.json { render json: @site_visit, location: url }
          format.html { redirect_to url }
        else
          flash[:alert] = @site_visit.errors.full_messages
          format.json { render json: { errors: flash[:alert] }, status: :unprocessable_entity }
          format.html { render 'new' }
        end
      else
        flash[:alert] = @site_visit.errors.full_messages
        errors = @site_visit.errors.full_messages
        errors = ['Could not register Site Visit on Sell.Do'] if errors.blank?
        format.json { render json: { errors: errors }, status: :unprocessable_entity }
        format.html { render 'new' }
      end
    end
  end

  def edit
    authorize([:admin, @site_visit])
    render layout: false
  end

  def update
    authorize([:admin, @site_visit])
    @site_visit.assign_attributes(permitted_attributes([:admin, @site_visit]))
    respond_to do |format|
      if (params.dig(:site_visit, :event).present? ? @site_visit.send("#{params.dig(:site_visit, :event)}!") : @site_visit.save)
        format.html { redirect_to admin_lead_site_visits_path(@lead), notice: 'Site Visit was successfully updated.' }
      else
        format.html { render :edit }
        format.json { render json: { errors: @site_visit.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def sync_with_selldo
    authorize([:admin, @site_visit])

    # Get site visit details from sell.do through API
    selldo_sv_id = @site_visit.third_party_references.where(crm_id: @crm_base.id).first.try(:reference_id)
    url = URI.join(ENV_CONFIG.dig(:selldo, :base_url), "/client/activities/#{selldo_sv_id}.json?api_key=#{@site_visit.project.selldo_api_key}&client_id=#{@site_visit.project.selldo_client_id}")
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = (url.scheme == 'https')
    req = Net::HTTP::Get.new(url)
    req["Content-Type"] = "application/json"


    respond_to do |format|
      begin
        resp = https.request(req)

        case resp
        when Net::HTTPSuccess
          if @site_visit.update_data_from_selldo(JSON.parse(resp.read_body))
            format.html { redirect_to request.referer, notice: 'Site Visit synced successfully.' }
          else
            format.html { redirect_to request.referer, alert: @site_visit.errors.full_messages }
          end
        else
          Rails.logger.error "[SiteVisit][SyncWithSelldo][API][ERR][#{@site_visit.id}]: #{resp.message}"
          format.html { redirect_to request.referer, alert: "Error encountered: #{resp.message}" }
        end
      rescue StandardError => e
        Rails.logger.error "[SiteVisit][SyncWithSelldo][ERR][#{@site_visit.id}]: #{e.message}"
        format.html { redirect_to request.referer, alert: 'Something went wrong. Please contact support' }
      end
    end
  end

  private

  def user_time_zone
    Time.use_zone(current_user.time_zone) { yield }
  end

  def set_crm_base
    @crm_base = Crm::Base.where(domain: ENV_CONFIG.dig(:selldo, :base_url)).first
    redirect_to request.referer, alert: 'Sell.do CRM integration not available' if params[:action] == 'sync_with_selldo' && @crm_base.blank?
  end

  def set_lead
    @lead = Lead.where(_id: params[:lead_id]).first
    redirect_to request.referer, alert: 'Lead Not found' if @lead.blank?
  end

  def set_site_visit
    @site_visit = SiteVisit.where(_id: params[:id]).first
    redirect_to request.referer, alert: 'Site visit Not found' if @site_visit.blank?
  end
end
