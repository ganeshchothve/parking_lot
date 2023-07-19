#
# Single point of entry for registering leads into IRIS with & without lead conflict cases.
#
class LeadRegistrationService
  attr_accessor :client, :params, :user, :errors, :project, :buyer, :buyer_created, :lead, :lead_created, :site_visit, :lead_manager, :cp_user, :selldo_crm_base, :manager

  #
  # Parameters
  #
  # client  - Client in which lead / walkin will get created
  # project - Project in which lead / walkin will get created
  # creator - User who is registering the lead / walkin
  # params  - Hash containing lead details
  #         - Must include { first_name, last_name, phone, email } optional { selldo_lead_id site_visit_params }
  #         - OR
  #         - Must include { lead_id } optional { selldo_lead_id site_visit_params }
  #
  def initialize(client, project, creator, params={})
    @client = client
    @params = params.with_indifferent_access
    @project = project
    @user = creator
    @errors = []
    @selldo_crm_base = Crm::Base.where(booking_portal_client_id: client.id, domain: ENV_CONFIG.dig(:selldo, :base_url)).first

    @errors << 'Client is required' if @client.blank?
    @errors << 'Project is required' if @project.blank?
    @errors << 'Params are missing' if @params.blank?

    #
    # Find CP user
    #
    @cp_user = if user && user.role.in?(%w(channel_partner cp_owner))
                 user
               else params[:manager_id].present?
                 User.in(role: %w(channel_partner cp_owner)).where(booking_portal_client_id: client.id, id: params[:manager_id]).first
               end
    @manager = @cp_user || @user
  end

  #
  # Overview about Lead Manager & its role in system:
  #
  # This service uses Lead Manager, an object which is used to resolve conflicts between different users adding same leads in the system (referred to as manager in this service) & tags the rightful owner/manager to the lead according to the conflict resolution logic chosen by(setting selected on) the client.
  #
  # For more on different settings of conflict resolution supported,
  # please check the comments & implementation of below defined method fetch_lead_manager
  #
  # Lead Manager is created,
  # - For every new SV scheduled by Current User
  # - AND
  # - For every Current User registering the Lead in the system with [Lead - Manager] mapping
  #
  # Lead is created only once. Its not created every time the Lead Manager is created.
  # It has One Lead to Many Lead Managers mapping.
  #
  # But, for each Site Visit, a Lead Manager is created. It has One SV to One Lead Manager mapping.
  #
  # ================================================================================================================
  #
  # Service description:
  #
  # Execution of this service will perform the following,
  #
  # - Raise errors in case of existing Lead Manager or SV is found.
  # - In case of existing User/Lead found, use that to create a new Lead Manager for current user
  # - In case of any error raised, it will rollback only the NEW objects created for Lead Manager, User, Lead & SV.
  # - Any existing User/Lead found will stay as is.
  #
  # ================================================================================================================
  #
  # High level steps to carry out:
  #
  # 1. Find or Create Lead Manager
  # 2. Find or Create User
  # 3. Find or Create Lead
  # 4. Find or Create SV
  #
  def execute

    begin
      if errors.blank?
        #
        # Check if lead manager is already present
        #
        fetch_lead_manager

        if errors.blank?
          #
          # Create a new Lead manager only if not found through fetch_lead_manager method OR SV needs to be tagged on existing Lead Manager
          #
          if lead_manager.blank? || @use_existing_lead_manager
            #
            # Create Lead Manager
            #
            @lead_manager ||= LeadManager.new(booking_portal_client_id: client.id, project_id: project.id, manager_id: manager.id, email: params[:email], phone: get_phone_from_params, first_name: params[:first_name], last_name: params[:last_name])
            #
            # Create inactive lead manager for re-visits scheduled by internal roles on active leads tagged with channel partners
            #
            @lead_manager.status = 'inactive' if @inactive_manager

            if @lead_manager.save
              #
              # Continue with registering lead with user account & sitevisit, only upon successful creation of Lead Manager,
              #
              create_lead_and_site_visit
              #
              # Push it into configured CRMs according to the available integrations.
              #
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

      if errors.blank?
        #
        # Tag manager on lead directly, in case of,
        # 1. Current manager is an internal role
        # 2. Lead conflict set to other than 'Site visit conducted'
        #
        if %w(client_level project_level no_conflict).include?(client.enable_lead_conflicts) || !manager.channel_partner?
          @lead_manager.tag!
        end
      end

    rescue StandardError => e
      #
      # Rollback & log in case of any unexpected error occurs.
      #
      @errors << I18n.t("controller.site_visits.errors.went_wrong")
      Rails.logger.error "[LeadRegistrationService][ERR] ERROR: #{e.message}\nTRACE: #{e.backtrace}"
      rollback
    end

    return [errors, lead_manager, buyer, lead, site_visit]
  end

  #
  # Fetch lead manager on the basis of lead conflicts setting configured on client.
  #
  def fetch_lead_manager
    #
    # CASE: If existing lead is copied to another project
    #
    if params[:lead_id].present?
      existing_lead_manager = LeadManager.where(booking_portal_client_id: client.id, lead_id: params[:lead_id]).first
      if existing_lead_manager.present?
        params.merge!(email: existing_lead_manager.email, phone: existing_lead_manager.phone, first_name: existing_lead_manager.first_name, last_name: existing_lead_manager.last_name)
      else
        #
        # If existing lead is not found through lead_id in params
        #
        @errors << 'Existing lead not found'
      end
    end

    #
    # Handle lead conflict behavior according to the setting on client
    #
    case client.enable_lead_conflicts

    when 'no_conflict'
      #
      # If lead duplication is disabled, maintain one lead per project irrespective of the managers
      #
      unless client.allow_lead_duplication?
        @lead_manager = LeadManager.where(booking_portal_client_id: client.id, project_id: project.id).or(get_query).first
      end

    when 'client_level'
      #
      # Try to find existing lead in any project but with a different partner manager. Only applicable for cp users
      # Do not apply the same rule for internal roles. For eg: Same lead can be added in another project by some other sales
      #
      lm = LeadManager.where(booking_portal_client_id: client.id).or(get_query)

      if lm.present?
        #
        # If current manager is a cp, then check if this lead is added by current cp earlier in any other project.
        # If not, don't allow him to add this lead.
        #
        if manager.channel_partner? && lm.distinct(:manager_id).exclude?(manager.id)

          @lead_manager = lm.first

        else
          #
          # Find existing lead in same project. If found, don't allow to register lead again.
          #
          if lm.where(project_id: project.id).present?
            @lead_manager = lm.first
          end
        end
      end

    when 'project_level'
      #
      # Find existing lead in same project. If found, don't allow to register lead again.
      # Same lead can be added in another project by a different partner manager
      #
      @lead_manager = LeadManager.where(booking_portal_client_id: client.id, project_id: project.id).or(get_query).first

    when 'site_visit_conducted'
      #
      # Exclude expired Lead managers while fetching
      #
      lm = LeadManager.where(booking_portal_client_id: client.id, project_id: project.id).or(get_query)

      tagged_lm = lm.tagged.first
      active_lm = lm.active.first

      if tagged_lm.blank?
        if active_lm.blank?
          #
          # CASES
          # 1: If Lead is added by internal role then it gets tagged right away, so it cannot be added again by any other user.
          # 2: If Lead is first added by cp user, lead manager gets created in draft. After that,
          #     a. Don't allow internal roles to add it again.
          #     b. It can be added by other cp users till one of the lead manager gets active status
          #
          if manager.channel_partner?
            #
            # CASE 2.a
            #
            #
            # First check if draft lead manager is present without site_visit_id (created only when lead is added without a sitevisit)
            #
            @lead_manager = lm.draft.where(manager_id: manager.id, site_visit_id: nil).first
            #
            # If site visit is being created for a lead for first time with current manager, then tag it to already created lead manager for that lead
            # OR
            # Treat it as creating a new lead manager with conflict conditions.
            #
            if site_visit_params.present? && @lead_manager
              @use_existing_lead_manager = true
            else
              @lead_manager = lm.draft.where(manager_id: manager.id).first
            end

          else
            #
            # CASE 2.b
            #
            @lead_manager = lm.draft.first
          end

        elsif site_visit_params.present? && !manager.channel_partner?
          #
          # Allow scheduling re-visits on active leads by admin/sales/internal roles
          # Do not allow it to Channel partners
          #
          # Create inactive Lead manager for such re-visits
          #
          @inactive_manager = true

        else
          @lead_manager = active_lm
        end

      elsif site_visit_params.present? && !manager.channel_partner? && !tagged_lm.manager.channel_partner?
        #
        # Allow all internal roles to schedule & conduct sitevisits for leads tagged to any of the internal roles
        #
        # Create inactive Lead manager for such visits / re-visits
        #
        @inactive_manager = true

      else
        @lead_manager = tagged_lm
      end

    end # END case-when
  end

  def create_lead_and_site_visit
    #
    # Create User account for buyer if its not already created
    #
    find_or_create_user

    if errors.blank? && buyer.present?
      #
      # Create lead for buyer if its not already created
      #
      find_or_create_lead

      if errors.blank? && lead.present?
        #
        # Create a new SV for buyer
        #
        create_site_visit

        if errors.blank? && lead_manager.present?
          #
          # Link lead manager with respective lead & sitevisit
          #
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
    @lead = buyer.leads.where(project_id: project.id, booking_portal_client_id: client.id).first unless client.allow_lead_duplication?

    if @lead.blank?
      #
      # Create new lead
      #
      @lead = buyer.leads.new(email: params[:email], phone: get_phone_from_params, first_name: params[:first_name], last_name: params[:last_name], project_id: project.id, booking_portal_client_id: client.id, third_party_references_attributes: (params[:third_party_references_attributes] || []))
      #
      # If Sell.do Lead create APIs are configured, then push it into sell.do if push_to_crm is set
      #
      @lead.push_to_crm = params[:push_to_crm] unless params[:push_to_crm].nil?
      #
      # If its a Kylas marketplace app, set owner id to flow it back into kylas.
      #
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
    if site_visit_params.present?

      if tpr = site_visit_params.dig(:third_party_references_attributes).try(:first).presence
        if tpr[:crm_id].present? && tpr[:reference_id].present?
          existing_site_visit = SiteVisit.where(booking_portal_client_id: client.id, lead_id: lead.id).reference_resource_exists?(tpr[:crm_id], tpr[:reference_id])
        end
      end

      if existing_site_visit.blank?
        sv_attrs = ActionController::Parameters.new(site_visit_params.as_json).permit(Pundit.policy(user, [:admin, SiteVisit.new]).permitted_attributes)

        attrs = {booking_portal_client_id: client.id, user_id: buyer.id}
        attrs[:manager_id] = manager.id if manager.present?

        sv_attrs.merge!(attrs)

        @site_visit = lead.site_visits.new(sv_attrs)

        unless @site_visit.save
          @errors += @site_visit.errors.full_messages
          rollback
        end

      else
        @errors << I18n.t("controller.site_visits.errors.site_visit_reference_id_already_exists", name: tpr[:reference_id])
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

    selldo_lead_id = if tprs = params[:third_party_references_attributes].presence
                       tprs.find { |x| x[:crm_id].to_s == @selldo_crm_base.id.to_s }.try(:[], :reference_id)
                     else
                       params[:selldo_lead_id].presence
                     end
    query << {lead_id: selldo_lead_id} if selldo_lead_id.present?

    query
  end

  def get_phone_from_params
    phone = Phonelib.parse(params[:phone]).to_s if params[:phone].present?
  end

  #
  # Push newly created lead / sitevisit into sell.do or Kylas CRM based on the CRM integrations present in this client.
  #
  def push_into_crm
    if lead.push_to_crm? && selldo_crm_base.present?
      push_lead_to_selldo
      site_visit.reload.push_in_crm(selldo_crm_base) if lead.reload.lead_id.present? && site_visit.present?
    end

    Kylas::SyncLeadToKylasWorker.perform_async(lead.id.to_s, site_visit.try(:id).try(:to_s)) if client.is_marketplace?
  end

  def push_lead_to_selldo
    #
    # Push lead into sell.do & rollback if it doesn't get pushed, with an error message.
    #
    selldo_api = Crm::Api::Post.where(booking_portal_client_id: client.id, resource_class: 'Lead', base_id: selldo_crm_base.id, is_active: true).first

    if selldo_api.present?
      result = selldo_api.execute(lead)
      api_log = result[:api_log]

      if api_log.present?
        if api_log.status == 'Success' && (resp = api_log.response.try(:first).presence)
          resp = (resp['selldo_lead_details'] || {}).with_indifferent_access
          lead.update(selldo_lead_registration_date: resp[:lead_created_at], lead_stage: resp[:stage])
          #
          # Update custom lead stage in selldo
          #
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
