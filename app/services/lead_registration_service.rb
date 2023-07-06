class LeadRegistrationService
  attr_accessor :client, :params, :user, :errors, :project, :buyer, :buyer_created, :lead, :lead_created, :site_visit, :lead_manager, :cp_user, :selldo_crm_base, :manager

  def initialize(client, project, user, params={})
    @client = client
    @params = params.with_indifferent_access
    @project = project
    @user = user
    @errors = []
    @selldo_crm_base = Crm::Base.where(booking_portal_client_id: client.id, domain: ENV_CONFIG.dig(:selldo, :base_url)).first

    @errors << 'Client is required' if @client.blank?
    @errors << 'Project is required' if @project.blank?
    @errors << 'Params are missing' if @params.blank?

    # Find CP user
    @cp_user = if user && user.role.in?(%w(channel_partner cp_owner))
                 user
               else params[:manager_id].present?
                 User.in(role: %w(channel_partner cp_owner)).where(booking_portal_client_id: client.id, id: params[:manager_id]).first
               end
    @manager = @cp_user || @user
  end

  def execute
    # 1. Find or Create Lead Manager
    # 2. Find or Create user
    # 3. Find or Create Lead
    # 4. Create SV

    if errors.blank?
      # Check if lead manager is already present
      fetch_lead_manager

      if errors.blank?
        if lead_manager.blank?
          # Create Lead Manager
          @lead_manager = LeadManager.new(booking_portal_client_id: client.id, project_id: project.id, manager_id: manager.id, email: params[:email], phone: get_phone_from_params, first_name: params[:first_name], last_name: params[:last_name])
          if @lead_manager.save
            # Register lead with user account & sitevisit
            create_lead_and_site_visit
            push_into_crm if errors.blank? && lead.present?
          else
            @errors += @lead_manager.errors.full_messages
            rollback
          end
        else
          @errors << I18n.t("controller.leads.errors.already_exists")
        end
      end
    end

    return [errors, lead_manager, buyer, lead, site_visit]
  end

  def fetch_lead_manager
    # TODO: Do the following checks here:
    # 1. Handle lead conflict behavior
    # 2. Exclude expired Lead managers while fetching

    # CASE: If existing lead is copied to another project
    if params[:lead_id].present?
      existing_lead_manager = LeadManager.where(booking_portal_client_id: client.id, lead_id: params[:lead_id]).first
      if existing_lead_manager.present?
        @lead_manager = LeadManager.where(booking_portal_client_id: client.id, project_id: project.id, lead_id: existing_lead_manager.lead_id).first
        params.merge!(email: existing_lead_manager.email, phone: existing_lead_manager.phone, first_name: existing_lead_manager.first_name, last_name: existing_lead_manager.last_name)
      else
        # If existing lead is not found through lead_id in params
        @errors << 'Existing lead not found'
      end
    else params[:email] || params[:phone]
      @lead_manager = LeadManager.where(booking_portal_client_id: client.id, project_id: project.id).or(get_query).first
    end
  end

  def create_lead_and_site_visit
    # Create User account for buyer if its not already created
    find_or_create_user
    if errors.blank? && buyer.present?
      # Create lead for buyer if its not already created
      find_or_create_lead
      if errors.blank? && lead.present?
        # Create a new SV for buyer
        create_site_visit
        if errors.blank? && lead_manager.present?
          # Link lead manager with respective lead & sitevisit
          attrs = {lead_id: lead.id, user_id: lead.user_id}
          attrs[:site_visit_id] = site_visit.id if site_visit.present?
          unless lead_manager.update(attrs)
            @errors += lead_manager.errors.full_messages
            rollback
          end
        end
      end
    end
  end

  def find_or_create_user
    @buyer = User.where(booking_portal_client_id: client.id).or(get_query).first
    if @buyer.blank?
      @buyer = User.new(booking_portal_client_id: client.id, email: params[:email], phone: get_phone_from_params, first_name: params[:first_name], last_name: params[:last_name], is_active: true)
      @buyer.skip_confirmation! # TODO: Remove this when customer login needs to be given
      if @buyer.save
        @buyer_created = true
      else
        @errors += @buyer.errors.full_messages
        rollback
      end
    else
      @buyer_created = false
      unless @buyer.buyer?
        @errors << I18n.t("controller.users.errors.already_registered")
        rollback
      end
    end
  end

  def find_or_create_lead
    @lead = buyer.leads.where(project_id: project.id, booking_portal_client_id: client.id).first
    if @lead.blank?
      # Create new lead
      @lead = buyer.leads.new(email: params[:email], phone: get_phone_from_params, first_name: params[:first_name], last_name: params[:last_name], project_id: project.id, booking_portal_client_id: client.id)
      # If Sell.do Lead create APIs are configured, then push it into sell.do if push_to_crm is set
      @lead.push_to_crm = params[:push_to_crm] unless params[:push_to_crm].nil?
      # If its a Kylas marketplace app, set owner id to flow it back into kylas.
      @lead.owner_id = user.id if client.is_marketplace? && user.present? && user.kylas_user_id.present?

      if @lead.save
        @lead_created = true
      else
        @errors += @lead.errors.full_messages
        rollback
      end
    else
      @lead_created = false
    end
  end

  def create_site_visit
    attrs = {booking_portal_client_id: client.id, user_id: buyer.id}
    attrs[:manager_id] = manager.id if manager.present?
    if site_visit_params.present?
      attrs[:scheduled_on] = site_visit_params[:scheduled_on] if site_visit_params[:scheduled_on].present?
      attrs[:creator_id] = site_visit_params[:creator_id] if site_visit_params[:creator_id].present?
      @site_visit = lead.site_visits.new(attrs)
      if @site_visit.save
      else
        @errors += @site_visit.errors.full_messages
        rollback
      end
    end
  end

  def site_visit_params
    params.dig(:lead, :site_visits_attributes, '0')
  end

  def get_query
    query = []
    query << {email: params[:email].downcase} if params[:email].present?
    query << {phone: get_phone_from_params} if params[:phone].present?
    #query << {lead_id: params[:lead_id]} if params[:lead_id].present?
    query
  end

  def get_phone_from_params
    phone = Phonelib.parse(params[:phone]).to_s if params[:phone].present?
  end

  # Push newly created lead / sitevisit into sell.do or Kylas CRM based on the CRM integrations present in this client.
  def push_into_crm
    if lead.push_to_crm? && selldo_crm_base.present?
      push_lead_to_selldo
      site_visit.push_in_crm(selldo_crm_base) if site_visit.present?
    end
    Kylas::SyncLeadToKylasWorker.perform_async(lead.id.to_s, site_visit.try(:id).try(:to_s)) if client.is_marketplace?
  end

  def push_lead_to_selldo
    # Push lead into sell.do & rollback if it doesn't get pushed, with an error message.
    selldo_api = Crm::Api::Post.where(booking_portal_client_id: client.id, resource_class: 'Lead', base_id: selldo_crm_base.id, is_active: true).first
    if selldo_api.present?
      result = selldo_api.execute(lead)
      api_log = result[:api_log]
      if api_log.present?
        if api_log.status == 'Success' && (resp = api_log.response.try(:first).presence)
          attrs[:lead_details] = (resp['selldo_lead_details'] || {}).with_indifferent_access
          lead.update(selldo_lead_registration_date: attrs.dig(:lead_details, :lead_created_at), lead_stage: attrs.dig(:lead_details, :stage))
          # Update custom lead stage in selldo
          SelldoLeadUpdater.perform_async(lead.id, {stage: 'registered'})
          SelldoLeadUpdater.perform_async(lead.id, {stage: 'confirmed'})
        else
          @errors << api_log.message
          rollback
        end
      else
        @errors << 'Facing issue while pushing lead into CRM'
        rollback
      end
    end
  end

  def rollback
    lead_manager.destroy if lead_manager.present? && lead_manager.persisted?
    site_visit.destroy if site_visit.present? && site_visit.persisted?
    lead.destroy if lead.present? && lead_created && lead.persisted?
    buyer.destroy if buyer.present? && buyer_created && buyer.persisted?
  end
end
