class Users::NotificationTokensController < ApplicationController
  before_action :authenticate_user!
  
  def update
    authorize current_user, :update?
    if params[:old_token].present?
      old_user = User.where(booking_portal_client_id: current_client.try(:id), "user_notification_tokens.token": params[:old_token]).first
      old_user.user_notification_tokens.where(token: params[:old_token]).first.try(:destroy) if old_user.present?
    end
    parameters = permitted_attributes([current_user_role_group, current_user])
    if parameters[:user_notification_tokens_attributes].length == 1 && parameters[:user_notification_tokens_attributes].first[:token] && current_user.user_notification_tokens.where(token: parameters[:user_notification_tokens_attributes].first[:token]).blank?
      current_user.assign_attributes(parameters)
    end
    respond_to do |format|
      if current_user.save
        subscribe_to_topic
        format.json { render json: {message: I18n.t("controller.notification_types.notice.updated"), user: current_user }, status: 200 }
      else
        format.json { render json: { errors: current_user.user_notification_tokens.collect{|x| x.errors.full_messages}.flatten.uniq }, status: :unprocessable_entity }
      end
    end
  end

  def subscribe_to_topic
    topic = "#{current_client.id}-#{current_project.id}-#{current_user.role}"
    fcm = FCM.new(current_client.notification_api_key)
    _request_header = {"Content-Type": "application/json", "Authorization": "key=#{fcm.api_key}"}
    body = { to: "/topics/#{topic}", registration_tokens: current_user.user_notification_tokens.collect{ |x| x.token } }
    uri = URI.join('https://iid.googleapis.com' ,"/iid/v1:batchAdd")
    resp = Net::HTTP.post(uri, body.to_json, _request_header)
  end
end