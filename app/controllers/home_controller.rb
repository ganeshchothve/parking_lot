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
            @user = User.new(booking_portal_client_id: current_client.id, email: params['email'], phone: params['phone'], first_name: params['first_name'], last_name: params['last_name'], lead_id: params[:lead_id], mixpanel_id: params[:mixpanel_id]) unless @user.present?
            @lead = Lead.new(email: params['email'], phone: params['phone'], first_name: params['first_name'], last_name: params['last_name'], lead_id: params[:lead_id], selldo_lead_registration_date: params.dig(:lead_details, :lead_created_at))
            if @user.save && (selldo_config_base.blank? || @project.save)
              @user.confirm #auto confirm user account
              @lead.assign_attributes(user_id: @user.id, project_id: @project.id)
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
            format.json { render json: {errors: 'Project not found' }, status: :unprocessable_entity }
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

