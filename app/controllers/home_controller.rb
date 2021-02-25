# TODO: replace all messages & flash messages
class HomeController < ApplicationController

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
          CpLeadActivityRegister.create_cp_lead_object(false, @lead, current_user, params[:lead_details]) if current_user.role?("channel_partner")
          format.json { render json: {lead: @lead, success: "Lead created successfully"}, status: :created }
        else
          @project = Project.new(booking_portal_client_id: current_client.id, name: params["project_name"], selldo_id: params["project_id"]) unless @project.present?
          @user = User.new(booking_portal_client_id: current_client.id, email: params['email'], phone: params['phone'], first_name: params['first_name'], last_name: params['last_name'], lead_id: params[:lead_id], mixpanel_id: params[:mixpanel_id]) unless @user.present?
          @lead = Lead.new(email: params['email'], phone: params['phone'], first_name: params['first_name'], last_name: params['last_name'], lead_id: params[:lead_id], selldo_lead_registration_date: params['lead_details']['lead_created_at'])
          if @project.save && @user.save
            @lead.assign_attributes(user_id: @user.id, project_id: @project.id)
            CpLeadActivityRegister.create_cp_lead_object(true, @lead, current_user, params[:lead_details]) if current_user.role?("channel_partner")
            if @lead.save
              format.json { render json: {lead: @lead, success: "Lead created successfully"}, status: :created }
            else
              format.json { render json: {errors: @lead.errors.full_messages.uniq}, status: :unprocessable_entity }
            end
          else
            format.json { render json: {errors: (@project.errors.full_messages.uniq.map{|e| "Project - "+ e } rescue []) + (@user.errors.full_messages.uniq.map{|e| "User - "+ e } rescue [])}, status: :unprocessable_entity }
          end
        end
      end
    end
  end

  private

  def get_query
    query = []
    query << {email: params['email']} if params[:email].present?
    query << {phone: params['phone']} if params[:phone].present?
    query << {lead_id: params['lead_id']} if params[:lead_id].present?
    query
  end

  def set_project
    @project = Project.where(selldo_id: params["project_id"]).first if params["project_id"].present?
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

