# TODO: replace all messages & flash messages
class HomeController < ApplicationController
  include LeadsHelper
  include LeadRegisteration

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
  end

  def terms_and_conditions
    @channel_partner = ChannelPartner.new
  end

  def cp_enquiryform
    @channel_partner = ChannelPartner.new
  end

  def select_client
    if current_user.role.in?(%w(superadmin))
      if current_client.present? && (Client.in(booking_portal_domains: current_domain).present? || current_client.projects.in(booking_portal_domains: current_domain).present?)
        current_user.update(selected_client_id: current_client.id)
        redirect_to home_path(current_user)
      elsif current_user.client_ids.count == 1
        current_user.update(selected_client_id: current_user.client_ids.first)
        redirect_to home_path(current_user)
      else
        if request.method == 'POST'
          current_user.selected_client_id = params[:selected_client_id]
          current_user.save
          redirect_to home_path(current_user)
        else
          render layout: 'devise'
        end
      end
    end
  end

  def register
    @resource = User.new
    if user_signed_in?
      redirect_to home_path(current_user)
      flash[:notice] = I18n.t("controller.notice.logged_in")
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

