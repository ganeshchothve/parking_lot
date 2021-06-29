# TODO: replace all messages & flash messages
class HomeController < ApplicationController
  include LeadsHelper

  skip_before_action :set_current_client, only: :welcome
  before_action :set_project, :set_user, :set_lead, only: :check_and_register

  def index
  end

  def welcome
    render layout: 'welcome'
  end

  def privacy_policy
    @channel_partner = ChannelPartner.new
    render layout: 'landing_page'
  end

  def terms_and_conditions
    @channel_partner = ChannelPartner.new
    render layout: 'landing_page'
  end

  def register
    @resource = User.new
    if user_signed_in?
      redirect_to home_path(current_user)
      flash[:notice] = "You have already been logged in"
    else
      store_cookies_for_registration
      render layout: "devise"
    end
  end

  def check_and_register
    authorize [:admin, Lead.new(project_id: @project.id)]
    unless request.xhr?
      redirect_to (user_signed_in? ? after_sign_in_path : root_path)
    else
      respond_to do |format|
        if @lead.present?
          if current_client.enable_lead_conflicts?
            CpLeadActivityRegister.create_cp_lead_object(@lead, current_user, params[:lead_details]) if current_user.role?("channel_partner")
            format.json { render json: {lead: @lead, success: "Lead created successfully"}, status: :created }
          else
            format.json { render json: {errors: "Lead already exists"}, status: :unprocessable_entity }
          end
        else
          if selldo_config_base.present?
            @project = Project.new(booking_portal_client_id: current_client.id, name: params["project_name"], selldo_id: params["project_id"]) unless @project.present?
          end

          if @project.present?
            @user = User.new(booking_portal_client_id: current_client.id, email: params['email'], phone: params['phone'], first_name: params['first_name'], last_name: params['last_name']) unless @user.present?
            @lead = @user.leads.new(email: params['email'], phone: params['phone'], first_name: params['first_name'], last_name: params['last_name'], project_id: @project.id)

            # Push lead first to sell.do & upon getting successful response, save it in IRIS. Same flow as when were using sell.do form for lead registration.
            crm_base = Crm::Base.where(domain: ENV_CONFIG.dig(:selldo, :base_url)).first
            selldo_api = Crm::Api::Post.where(resource_class: 'Lead', base_id: crm_base.id, is_active: true).first if crm_base.present?
            if selldo_api.present?
              selldo_api.execute(@lead)
              api_log = ApiLog.where(resource_id: @lead.id).first
              if resp = api_log.response.try(:first).presence
                @user.lead_id = resp['sell_do_lead_id'] if @user.lead_id.blank?
                params[:lead_details] = resp['selldo_lead_details']
                #
                # Don't create lead if it exists in sell.do when lead conflicts is disabled.
                unless current_client.enable_lead_conflicts?
                  format.json { render json: {errors: "Lead already exists"}, status: :unprocessable_entity and return } if params.dig(:lead_details, :lead_already_exists).present?
                end
              end
            end

            if selldo_api.blank? || (api_log.present? && api_log.status == 'Success')
              if @user.save && (selldo_config_base.blank? || @project.save)
                @user.confirm #auto confirm user account
                @lead.assign_attributes(selldo_lead_registration_date: params.dig(:lead_details, :lead_created_at))

                cp_lead_activity = CpLeadActivityRegister.create_cp_lead_object(@lead, current_user, params[:lead_details]) if current_user.role?("channel_partner")

                if @lead.save
                  if cp_lead_activity.present?
                    if cp_lead_activity.save
                      format.json { render json: {lead: @lead, success: "Lead created successfully"}, status: :created }
                    else
                      format.json { render json: {errors: 'Something went wrong while adding lead. Please contact support'}, status: :unprocessable_entity }
                    end
                  else
                    format.json { render json: {lead: @lead, success: "Lead created successfully"}, status: :created }
                  end
                else
                  format.json { render json: {errors: @lead.errors.full_messages.uniq}, status: :unprocessable_entity }
                end
              else
                format.json { render json: {errors: (@project.errors.full_messages.uniq.map{|e| "Project - "+ e } rescue []) + (@user.errors.full_messages.uniq.map{|e| "User - "+ e } rescue [])}, status: :unprocessable_entity }
              end
            else
              format.json { render json: {errors: api_log.message}, status: :unprocessable_entity }
            end
          else
            format.json { render json: {errors: 'Project not found' }, status: :not_found }
          end
        end
      end
    end
  end

  private

  # def set_project_wise_flag
  #   if params[:lead_id].present?
  #     @is_interested_for_project = FetchLeadData.get(params[:lead_id], params[:project_name], current_client)
  #     format.json { render json: { errors: 'There was some error while fetching lead data from Sell.Do. Please contact administrator.', status: :unprocessable_entity } } && return if @is_interested_for_project == 'error'
  #   end
  # end

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
    _query = get_query
    @user = User.or(_query).first if _query.present?
    render json: {errors: 'User with these details is already registered with a different role' }, status: :unprocessable_entity and return if @user.present? && !@user.buyer?
  end

  def set_lead
    leads = Lead.or(get_query)
    if @project.present?
      @lead = leads.where({project_id: @project.id}).first
    end
  end

  def store_cookies_for_registration
    User::ALLOWED_UTM_KEYS.each do |key|
      cookies[key] = params[key] if params[key].present?
    end
  end
end

