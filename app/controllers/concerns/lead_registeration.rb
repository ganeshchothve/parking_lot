module LeadRegisteration
  extend ActiveSupport::Concern

  included do
    #before_action :set_project, :set_user, :set_lead, :set_customer_search, only: :check_and_register
    before_action :set_project, :set_customer_search, only: :check_and_register
  end

  def check_and_register
    authorize [:admin, Lead.new(project_id: @project.id)]
    unless request.xhr?
      redirect_to (user_signed_in? ? after_sign_in_path_for(current_user) : root_path)
    else
      respond_to do |format|
        if selldo_config_base(current_client).present?
          @project = Project.new(booking_portal_client_id: current_client.id, name: params["project_name"], selldo_id: params["project_id"]) unless @project.present?
        end

        if @project.present?
          if @project.persisted? || @project.save
            #if params[:lead_id]
            #  add_existing_lead_to_project_flow(format)
            #else
            #  add_new_lead_flow(format)
            #end

            errors, lead_manager, buyer, lead, site_visit = LeadRegistrationService.new(current_client, @project, current_user, params.permit!.to_h).execute

            if errors.present?
              format.json { render json: {errors: errors}, status: :unprocessable_entity }
            else
              update_customer_search_to_sitevisit(lead) if @customer_search.present?
              format.json { render json: {lead: lead, success: site_visit.present? ? I18n.t("controller.site_visits.notice.created") : I18n.t("controller.leads.notice.created")}, status: :created }
            end
          else
            format.json { render json: {errors: @project.errors.full_messages }, status: :unprocessable_entity }
          end
        else
          format.json { render json: {errors: I18n.t("controller.projects.alert.not_found") }, status: :not_found }
        end
      end
    end
  end

  private

  def set_project
    if params["project_id"].present?
      if selldo_config_base(current_client).present?
        @project = Project.where(selldo_id: params["project_id"], booking_portal_client_id: current_client.id).first
      else
        @project = Project.where(id: params['project_id'], booking_portal_client_id: current_client.id).first
      end
    end
  end

  def set_customer_search
    @customer_search = CustomerSearch.where(booking_portal_client_id: current_client.try(:id), id: params[:customer_search_id]).first if params[:customer_search_id].present?
  end

  def update_customer_search_to_sitevisit(lead)
    @customer_search.update(customer: lead, step: 'sitevisit')
    response.set_header('location',admin_customer_search_url(@customer_search))
  end

  #def add_existing_lead_to_project_flow(format)
  #  @new_lead = @user.leads.new(email: @lead.email, phone: @lead.phone, first_name: @lead.first_name, last_name: @lead.last_name, project_id: @project.id, manager_id: params[:manager_id], booking_portal_client_id: current_client.id)
  #  @new_lead.push_to_crm = params[:push_to_crm] unless params[:push_to_crm].nil?
  #  save_lead(format, @new_lead, true)
  #end

  #def add_new_lead_flow(format)
  #  unless @user.present?
  #    @user = User.new(booking_portal_client_id: current_client.id, email: params['email'], phone: params['phone'], first_name: params['first_name'], last_name: params['last_name'], is_active: true)
  #    @user.skip_confirmation! # TODO: Remove this when customer login needs to be given
  #  end

  #  @lead = @user.leads.new(email: params['email'], phone: params['phone'], first_name: params['first_name'], last_name: params['last_name'], project_id: @project.id, manager_id: params[:manager_id], booking_portal_client_id: current_user.try(:booking_portal_client_id) || params['booking_portal_client_id'])
  #  @lead.push_to_crm = params[:push_to_crm] unless params[:push_to_crm].nil?

  #  save_lead(format, @lead)
  #end

  #def save_lead(format, lead, existing=false)
  #  push_lead_to_selldo(format, lead) do |selldo_api, api_log|
  #    if lead.valid?
  #      if existing || (@user.save && (selldo_config_base(@user.booking_portal_client).blank? || @project.save))
  #        lead.assign_attributes(selldo_lead_registration_date: params.dig(:lead_details, :lead_created_at))
  #        lead.assign_attributes(lead_stage: params.dig(:lead_details, :stage))
  #        lead.assign_attributes(permitted_attributes([:admin, lead])) if params[:lead].present?
  #        lead.owner_id = current_user.id if user_signed_in? && current_user.try(:kylas_user_id).present? && current_user.booking_portal_client.try(:is_marketplace?)

  #        check_if_lead_added_by_channel_partner(lead) do |lead_manager|
  #          if lead_manager.blank? || lead_manager.valid?
  #            if lead.save
  #              # Update selldo lead stage & push Site visits
  #              site_visit = lead.site_visits.first
  #              if selldo_api && selldo_api.base.present?
  #                update_selldo_lead_stage(lead)
  #                sv_selldo_api, sv_api_log = site_visit.push_in_crm(selldo_api.base) if site_visit.present?
  #              end
  #              if lead_manager.present?
  #                if lead_manager.save
  #                  Kylas::SyncLeadToKylasWorker.perform_async(lead.id.to_s, site_visit.try(:id).try(:to_s))
  #                  update_customer_search_to_sitevisit(lead) if @customer_search.present?

  #                  format.json { render json: {lead: lead, success: site_visit.present? ? I18n.t("controller.site_visits.notice.created") : I18n.t("controller.leads.notice.created")}, status: :created }
  #                else
  #                  format.json { render json: {errors: 'Something went wrong while adding lead. Please contact support'}, status: :unprocessable_entity }
  #                end
  #              else
  #                Kylas::SyncLeadToKylasWorker.perform_async(lead.id.to_s, site_visit.try(:id).try(:to_s))
  #                update_customer_search_to_sitevisit(lead) if @customer_search.present?

  #                format.json { render json: {lead: lead, success: site_visit.present? ? I18n.t("controller.site_visits.notice.created") : I18n.t("controller.leads.notice.created")}, status: :created }
  #              end
  #            else
  #              format.json { render json: {errors: lead.errors.full_messages.uniq}, status: :unprocessable_entity }
  #            end
  #          else
  #            format.json { render json: {errors: lead_manager.errors.full_messages.uniq}, status: :unprocessable_entity }
  #          end
  #        end
  #      else
  #        format.json { render json: {errors: (@project.errors.full_messages.uniq.map{|e| "#{I18n.t('mongoid.models.project.one')} - "+ e } rescue []) + (@user.errors.full_messages.uniq.map{|e| "#{ I18n.t('mongoid.models.user.one')} - "+ e } rescue [])}, status: :unprocessable_entity }
  #      end
  #    else
  #      format.json { render json: {errors: @lead.errors.full_messages.uniq}, status: :unprocessable_entity }
  #    end
  #  end
  #end

  #def check_if_lead_added_by_channel_partner(lead)
  #  if current_user&.role&.in?(%w(channel_partner cp_owner))
  #    lead_manager = LeadManagerRegister.create_cp_lead_object(lead, current_user, (params[:lead_details] || {}))
  #  elsif params[:manager_id].present?
  #    cp_user = User.all.in(role: %w(channel_partner cp_owner)).where(booking_portal_client_id: current_client.try(:id), id: params[:manager_id]).first
  #    lead_manager = LeadManagerRegister.create_cp_lead_object(lead, cp_user, (params[:lead_details] || {})) if cp_user
  #  end

  #  yield(lead_manager)
  #end

  #def push_lead_to_selldo(format, lead)
  #  if lead.push_to_crm?
  #    # Push lead first to sell.do & upon getting successful response, save it in IRIS. Same flow as when were using sell.do form for lead registration.
  #    crm_base = Crm::Base.where(booking_portal_client_id: current_client.try(:id), domain: ENV_CONFIG.dig(:selldo, :base_url)).first
  #    selldo_api = Crm::Api::Post.where(booking_portal_client_id: current_client.try(:id), resource_class: 'Lead', base_id: crm_base.id, is_active: true).first if crm_base.present?
  #    if selldo_api.present?
  #      selldo_api.execute(lead)
  #      api_log = ApiLog.where(booking_portal_client_id: current_client.try(:id), resource_id: lead.id).first
  #      if resp = api_log.response.try(:first).presence
  #        params[:lead_details] = resp['selldo_lead_details']
  #        #
  #        # Don't create lead if it exists in sell.do when lead conflicts is disabled.
  #        #unless current_client.enable_lead_conflicts?
  #        #  render json: {errors: "Lead already exists"}, status: :unprocessable_entity and return if params.dig(:lead_details, :lead_already_exists).present?
  #        #end
  #      end
  #    end
  #  end

  #  if selldo_api.blank? || (api_log.present? && api_log.status == 'Success')
  #    yield(selldo_api, api_log)
  #  else
  #    format.json { render json: {errors: api_log.message}, status: :unprocessable_entity }
  #  end
  #end

  #def update_selldo_lead_stage(lead)
  #  SelldoLeadUpdater.perform_async(lead.id, {stage: 'registered'})
  #  SelldoLeadUpdater.perform_async(lead.id, {stage: 'confirmed'})
  #end


  # def set_project_wise_flag
  #   if params[:lead_id].present?
  #     @is_interested_for_project = FetchLeadData.get(params[:lead_id], params[:project_name], current_client)
  #     format.json { render json: { errors: 'There was some error while fetching lead data from Sell.Do. Please contact administrator.', status: :unprocessable_entity } } && return if @is_interested_for_project == 'error'
  #   end
  # end

  #def get_query
  #  query = []
  #  query << {email: params['email']} if params[:email].present?
  #  query << {phone: params['phone']} if params[:phone].present?
  #  query << {lead_id: params['lead_id']} if params[:lead_id].present?
  #  query
  #end

  #def set_user
  #  if params[:lead_id]
  #    @lead = Lead.where(id: params[:lead_id], booking_portal_client_id: current_client.id).first
  #    @user = @lead.user
  #  else
  #    _query = get_query
  #    @user = User.where(booking_portal_client_id: current_client.id).or(_query).first if _query.present?
  #    render json: {errors: I18n.t("controller.users.errors.already_registered") }, status: :unprocessable_entity and return if @user.present? && !@user.buyer?
  #  end
  #end

  #def set_lead
  #  if params[:lead_id]
  #    render json: {errors: I18n.t("controller.leads.errors.already_exists") }, status: :unprocessable_entity and return if @user.leads.where(project_id: @project.id).present?
  #  else
  #    leads = Lead.where(booking_portal_client_id: current_client.id).or(get_query)
  #    if @project.present?
  #      @lead = leads.where({project_id: @project.id}).first
  #    end
  #  end
  #end
end
