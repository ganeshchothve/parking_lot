# TODO: replace all messages & flash messages
class HomeController < ApplicationController
  include LeadsHelper
  include LeadRegisteration

  skip_before_action :set_current_client, only: :welcome

  def index
    render layout: 'landing_page'
  end

  def welcome
    render layout: 'welcome'
  end

  def signed_up
    @user = User.where(id: params[:user_id]).first
    render layout: 'devise'
  end

  def cp_signed_up_with_inactive_account
    @user = User.where(id: params[:user_id]).first
    render layout: 'devise'
  end

  def privacy_policy
    @channel_partner = ChannelPartner.new
    render layout: 'landing_page'
  end

  def terms_and_conditions
    @channel_partner = ChannelPartner.new
    render layout: 'landing_page'
  end

  def cp_enquiryform
    @channel_partner = ChannelPartner.new
    render layout: 'landing_page'
  end

  def select_project
    if current_user.buyer?
      if current_user.leads.count == 1
        current_user.update(selected_lead: (lead = current_user.leads.first), selected_project: lead.project)
        redirect_to home_path(current_user)
      else
        if request.method == 'POST'
          current_user.selected_lead_id = params[:selected_lead_id]
          lead = Lead.where(id: params[:selected_lead_id]).first
          current_user.selected_project_id = lead.project_id if lead
          current_user.save
          redirect_to home_path(current_user)
        else
          @leads = current_user.leads.all
          render layout: 'devise'
        end
      end
    elsif !current_user.role.in?(User::ALL_PROJECT_ACCESS + %w(channel_partner))
      if current_user.project_ids.count == 1
        current_user.update(selected_project_id: current_user.project_ids.first)
        redirect_to home_path(current_user)
      else
        if request.method == 'POST'
          current_user.selected_project_id = params[:selected_project_id]
          current_user.save
          redirect_to home_path(current_user)
        else
          project_ids = current_user.project_ids.map {|x| BSON::ObjectId(x) }
          @projects = Project.where(_id: {'$in': project_ids}).all
          render layout: 'devise'
        end
      end
    end
  end

  def register
    @resource = User.new
    if user_signed_in?
      redirect_to home_path(current_user)
      flash[:notice] = "You have already been logged in"
    else
      store_cookies_for_registration
      @lead = Lead.new
      render layout: "devise"
    end
  end

  private

  def store_cookies_for_registration
    User::ALLOWED_UTM_KEYS.each do |key|
      cookies[key] = params[key] if params[key].present?
    end
  end
end

