module LeadRegisteration
  extend ActiveSupport::Concern

  included do
    before_action :set_project, :set_user, :set_lead, :set_customer_search, only: :check_and_register
    around_action :user_time_zone, if: :current_user
  end

  def check_and_register
    authorize [:admin, Lead.new(project_id: @project.id)]
    unless request.xhr?
      redirect_to (user_signed_in? ? after_sign_in_path : root_path)
    else
      respond_to do |format|
        if params[:lead_id].blank? && @lead.present?
          if current_client.enable_lead_conflicts?
            CpLeadActivityRegister.create_cp_lead_object(@lead, current_user, params[:lead_details]) if current_user&.role.in?(%w(channel_partner cp_owner))
            format.json { render json: {lead: @lead, success: "Lead created successfully"}, status: :created }
          else
            format.json { render json: {errors: "Lead already exists"}, status: :unprocessable_entity }
          end
        else
          if selldo_config_base.present?
            @project = Project.new(booking_portal_client_id: current_client.id, name: params["project_name"], selldo_id: params["project_id"]) unless @project.present?
          end

          if @project.present?
            if params[:lead_id]
              add_existing_lead_to_project_flow(format)
            else
              add_new_lead_flow(format)
            end
          else
            format.json { render json: {errors: 'Project not found' }, status: :not_found }
          end
        end
      end
    end
  end

  private

  def user_time_zone
    Time.use_zone(current_user.time_zone) { yield }
  end

  def add_existing_lead_to_project_flow(format)
    @new_lead = @user.leads.new(email: @lead.email, phone: @lead.phone, first_name: @lead.first_name, last_name: @lead.last_name, project_id: @project.id, manager_id: params[:manager_id], push_to_crm: params[:push_to_crm])

    save_lead(format, @new_lead, true)
  end

  def add_new_lead_flow(format)
    unless @user.present?
      @user = User.new(booking_portal_client_id: current_client.id, email: params['email'], phone: params['phone'], first_name: params['first_name'], last_name: params['last_name'], is_active: false)
      @user.skip_confirmation! # TODO: Remove this when customer login needs to be given
    end

    @lead = @user.leads.new(email: params['email'], phone: params['phone'], first_name: params['first_name'], last_name: params['last_name'], project_id: @project.id, manager_id: params[:manager_id], push_to_crm: params[:push_to_crm])

    save_lead(format, @lead)
  end

  def save_lead(format, lead, existing=false)
    push_lead_to_selldo(format, lead) do |selldo_api, api_log|
      if existing || (@user.save && (selldo_config_base.blank? || @project.save))
        lead.assign_attributes(selldo_lead_registration_date: params.dig(:lead_details, :lead_created_at))
        lead.assign_attributes(permitted_attributes([:admin, lead])) if params[:lead].present?

        check_if_lead_added_by_channel_partner(lead) do |cp_lead_activity|
          if lead.save
            # Update selldo lead stage & push Site visits
            if selldo_api && selldo_api.base.present?
              update_selldo_lead_stage(lead)
              site_visit = lead.site_visits.first
              sv_selldo_api, sv_api_log = site_visit.push_in_crm(selldo_api.base)
            end

            if cp_lead_activity.present?
              if cp_lead_activity.save
                update_customer_search_to_sitevisit(lead) if @customer_search.present?

                format.json { render json: {lead: lead, success: "Lead created successfully"}, status: :created }
              else
                format.json { render json: {errors: 'Something went wrong while adding lead. Please contact support'}, status: :unprocessable_entity }
              end
            else
              update_customer_search_to_sitevisit(lead) if @customer_search.present?

              format.json { render json: {lead: lead, success: "Lead created successfully"}, status: :created }
            end
          else
            format.json { render json: {errors: lead.errors.full_messages.uniq}, status: :unprocessable_entity }
          end
        end
      else
        format.json { render json: {errors: (@project.errors.full_messages.uniq.map{|e| "Project - "+ e } rescue []) + (@user.errors.full_messages.uniq.map{|e| "User - "+ e } rescue [])}, status: :unprocessable_entity }
      end
    end
  end

  def check_if_lead_added_by_channel_partner(lead)
    if current_user&.role&.in?(%w(channel_partner cp_owner))
      cp_lead_activity = CpLeadActivityRegister.create_cp_lead_object(lead, current_user, (params[:lead_details] || {}))
    elsif params[:manager_id].present?
      cp_user = User.all.in(role: %w(channel_partner cp_owner)).where(id: params[:manager_id]).first
      cp_lead_activity = CpLeadActivityRegister.create_cp_lead_object(lead, cp_user, (params[:lead_details] || {})) if cp_user
    end

    yield(cp_lead_activity)
  end

  def push_lead_to_selldo(format, lead)
    if lead.push_to_crm?
      # Push lead first to sell.do & upon getting successful response, save it in IRIS. Same flow as when were using sell.do form for lead registration.
      crm_base = Crm::Base.where(domain: ENV_CONFIG.dig(:selldo, :base_url)).first
      selldo_api = Crm::Api::Post.where(resource_class: 'Lead', base_id: crm_base.id, is_active: true).first if crm_base.present?
      if selldo_api.present?
        selldo_api.execute(lead)
        api_log = ApiLog.where(resource_id: lead.id).first
        if resp = api_log.response.try(:first).presence
          params[:lead_details] = resp['selldo_lead_details']
          #
          # Don't create lead if it exists in sell.do when lead conflicts is disabled.
          #unless current_client.enable_lead_conflicts?
          #  render json: {errors: "Lead already exists"}, status: :unprocessable_entity and return if params.dig(:lead_details, :lead_already_exists).present?
          #end
        end
      end
    end

    if selldo_api.blank? || (api_log.present? && api_log.status == 'Success')
      yield(selldo_api, api_log)
    else
      format.json { render json: {errors: api_log.message}, status: :unprocessable_entity }
    end
  end

  def update_selldo_lead_stage(lead)
    SelldoLeadUpdater.perform_async(lead.id, {stage: 'registered'})
    SelldoLeadUpdater.perform_async(lead.id, {stage: 'confirmed'})
  end


  # def set_project_wise_flag
  #   if params[:lead_id].present?
  #     @is_interested_for_project = FetchLeadData.get(params[:lead_id], params[:project_name], current_client)
  #     format.json { render json: { errors: 'There was some error while fetching lead data from Sell.Do. Please contact administrator.', status: :unprocessable_entity } } && return if @is_interested_for_project == 'error'
  #   end
  # end

  def set_customer_search
    @customer_search = CustomerSearch.where(id: params[:customer_search_id]).first if params[:customer_search_id].present?
  end

  def update_customer_search_to_sitevisit(lead)
    @customer_search.update(customer: lead, step: 'sitevisit')
    response.set_header('location',admin_customer_search_url(@customer_search))
  end

  def get_query
    query = []
    query << {email: params['email']} if params[:email].present?
    query << {phone: params['phone']} if params[:phone].present?
    query << {lead_id: params['lead_id']} if params[:lead_id].present?
    query
  end

  def set_project
    if params["project_id"].present?
      if selldo_config_base.present?
        @project = Project.where(selldo_id: params["project_id"]).first
      else
        @project = Project.where(id: params['project_id']).first
      end
    end
  end

  def set_user
    if params[:lead_id]
      @lead = Lead.where(id: params[:lead_id]).first
      @user = @lead.user
    else
      _query = get_query
      @user = User.or(_query).first if _query.present?
      render json: {errors: 'User with these details is already registered with a different role' }, status: :unprocessable_entity and return if @user.present? && !@user.buyer?
    end
  end

  def set_lead
    if params[:lead_id]
      render json: {errors: 'Lead already exists' }, status: :unprocessable_entity and return if @user.leads.where(project_id: @project.id).present?
    else
      leads = Lead.or(get_query)
      if @project.present?
        @lead = leads.where({project_id: @project.id}).first
      end
    end
  end
end