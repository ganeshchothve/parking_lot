require 'net/http'
class SelldoLeadUpdater
  include Sidekiq::Worker
  include ApplicationHelper

  def perform(user_id, op_hash={})
    return false if Rails.env.test?
    user = User.where(id: user_id).first
    return false unless user
    op_hash = op_hash.with_indifferent_access
    default_op_hash = { 'action' => 'add_portal_stage_and_token_number' }
    op_hash = default_op_hash.merge(op_hash)
    operation = op_hash.delete 'action'
    self.send(operation, user, op_hash) if self.respond_to?(operation)
  end

  def add_portal_stage_and_token_number(user, payload={})
    return false if payload.blank?
    stage = payload['stage']
    options = payload['options']

    priority = PortalStagePriority.all.collect{|x| [x.stage, x.priority]}.to_h
    if stage.present? && priority[stage].present?
      if user.portal_stages.empty?
        user.portal_stages << PortalStage.new(stage: stage, priority: priority[stage])
      elsif user.portal_stage.priority.to_i <= priority[stage].to_i
        user.portal_stages.where(stage:  stage).present? ? user.portal_stages.where(stage:  stage).first.set(updated_at: Time.now, priority: priority[stage]) : user.portal_stages << PortalStage.new(stage: stage, priority: priority[stage])
      end
      if stage == 'payment_done' && options.try(:[], 'token_number').present?
        token_numbers = user.receipts.in(status: %w(success clearance_pending)).distinct(:token_number)
      end

      params = { portal_stage: stage }
      params[:token_number] = token_numbers if token_numbers.present?
      custom_hash = { custom_data: params }
      sell_do(user, custom_hash)
    else
      user.portal_stage
    end
  end

  def add_campaign_response(user, payload={})
    if payload.present?
      params = {
        sell_do: {
          form: {
            lead: {
              phone: user.phone
            }
          }
        }
      }
      params[:sell_do][:form][:lead][:source] = payload['source'] if payload['source'].present?
      params[:sell_do][:form][:lead][:sub_source] = payload['sub_source'] if payload['sub_source'].present?
      params[:sell_do][:form][:lead][:project_id] = payload['project_id'] if payload['project_id'].present?
      if payload['api_key'].present? && user.buyer?
        params.merge!({ api_key: payload['api_key'] })
        puts params
        RestClient.post(ENV_CONFIG['selldo']['base_url'] + "/api/leads/create.json", params)
      end
    else
      puts payload
    end
  end

  def sell_do(user, data={})
    score = 10
    MixpanelPusherWorker.perform_async(user.mixpanel_id, stage, {}) if current_client.mixpanel_token.present?
    if current_client.selldo_api_key.present?
      if user.buyer? && user.lead_id.present?
        params = {
          lead_id: user.lead_id,
          mixpanel_id: (user.mixpanel_id.present? && user.mixpanel_id != "undefined" && user.mixpanel_id != "null") ? user.mixpanel_id : nil,
          score: score,
          api_key: current_client.selldo_api_key
        }
        params = params.merge(data)
        puts params
        RestClient.post(ENV_CONFIG['selldo']['base_url'] + "/api/leads/create", params)
      end
    end
  end
end
