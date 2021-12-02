require 'net/http'
class SelldoLeadUpdater
  include Sidekiq::Worker
  include ApplicationHelper

  def perform(lead_id, op_hash={})
    return false if Rails.env.test?
    lead = Lead.where(id: lead_id).first || User.where(id: lead_id).first
    return false unless lead

    if lead.is_a?(User) && lead.role.in?(%w(cp_owner channel_partner))
      cp_user = lead
      op_hash = op_hash.with_indifferent_access
      operation = op_hash.delete 'action'
      self.send(operation, cp_user, op_hash) if self.respond_to?(operation)
    else
      op_hash = op_hash.with_indifferent_access
      default_op_hash = { 'action' => 'add_portal_stage_and_token_number' }
      op_hash = default_op_hash.merge(op_hash)
      operation = op_hash.delete 'action'
      self.send(operation, lead, op_hash) if self.respond_to?(operation)
    end
  end

  def add_cp_portal_stage(user, payload={})
    return false if payload.blank?
    stage = payload['stage']
    selldo_api_key = payload['selldo_api_key']
    selldo_client_id = payload['selldo_client_id']

    priority = PortalStagePriority.where(role: user.role).collect{|x| [x.stage, x.priority]}.to_h
    if stage.present? && priority[stage].present?
      if user.portal_stages.empty?
        user.portal_stages << PortalStage.new(stage: stage, priority: priority[stage])
      elsif user.portal_stage.priority.to_i <= priority[stage].to_i
        user.portal_stages.where(stage:  stage).present? ? user.portal_stages.where(stage:  stage).first.set(updated_at: Time.now, priority: priority[stage]) : user.portal_stages << PortalStage.new(stage: stage, priority: priority[stage])
      end
      params = { portal_stage: stage }
      custom_hash = {lead: params}
    else
      user.portal_stage
    end

    selldo_base_url = ENV_CONFIG['selldo']['base_url'].chomp('/')
    if custom_hash.present? && user.lead_id.present? && selldo_base_url.present? && selldo_api_key.present? && selldo_client_id.present?
      params = {
        api_key: selldo_api_key,
        client_id: selldo_client_id,
        not_clear_custom_fields: true
      }
      params = params.merge(custom_hash)
      url = selldo_base_url + "/client/leads/#{user.lead_id}.json"

      Rails.logger.info "[SelldoLeadUpdater][CPPortalStage][INFO][Params] #{params}"
      Rails.logger.info "[SelldoLeadUpdater][CPPortalStage][INFO][POST] #{url}"

      RestClient.put(url, params)
    end
  end

  def push_cp_data(user, payload={})
    return false unless payload.present? && payload[:lead].present?
    selldo_api_key = payload['selldo_api_key']
    selldo_client_id = payload['selldo_client_id']

    payload[:lead] ||= {}
    custom_hash = {lead: payload[:lead]}
    selldo_base_url = ENV_CONFIG['selldo']['base_url'].chomp('/')
    if custom_hash.present? && user.lead_id.present? && selldo_base_url.present? && selldo_api_key.present? && selldo_client_id.present?
      params = {
        api_key: selldo_api_key,
        client_id: selldo_client_id,
        not_clear_custom_fields: true
      }
      params = params.merge(custom_hash)
      url = selldo_base_url + "/client/leads/#{user.lead_id}.json"

      Rails.logger.info "[SelldoLeadUpdater][CPData][INFO][Params] #{params}"
      Rails.logger.info "[SelldoLeadUpdater][CPData][INFO][POST] #{url}"

      RestClient.put(url, params)
    end
  end

  def add_portal_stage_and_token_number(lead, payload={})
    return false if payload.blank?
    stage = payload['stage']

    priority = PortalStagePriority.where(role: 'user').collect{|x| [x.stage, x.priority]}.to_h
    if stage.present? && priority[stage].present?
      params = {}
      if lead.portal_stages.empty?
        lead.portal_stages << PortalStage.new(stage: stage, priority: priority[stage])
      elsif lead.portal_stage.priority.to_i <= priority[stage].to_i
        lead.portal_stages.where(stage:  stage).present? ? lead.portal_stages.where(stage:  stage).first.set(updated_at: Time.now, priority: priority[stage]) : lead.portal_stages << PortalStage.new(stage: stage, priority: priority[stage])
      end
      params[:custom_portal_stage] = lead.portal_stage.stage if lead.portal_stage.present?

      if stage == 'payment_done'
        token_numbers = lead.receipts.in(status: %w(success clearance_pending)).nin(token_number: ['', nil]).all.map(&:get_token_number)
        params[:custom_token_number] = token_numbers.join(',') if token_numbers.present?
      end

      if params.present?
        custom_hash = {lead: params}
        sell_do(lead, custom_hash)
      end
    else
      lead.portal_stage
    end
  end

  def add_campaign_response(lead, payload={})
    selldo_base_url = ENV_CONFIG['selldo']['base_url'].chomp('/')
    if payload.present?
      params = {
        sell_do: {
          form: {
            lead: {
              phone: lead.phone
            }
          }
        }
      }
      params[:sell_do][:form][:lead][:source] = payload['source'] if payload['source'].present?
      params[:sell_do][:form][:lead][:sub_source] = payload['sub_source'] if payload['sub_source'].present?
      params[:sell_do][:form][:lead][:project_id] = payload['project_id'] if payload['project_id'].present?
      if payload['api_key'].present? && selldo_base_url.present?
        params.merge!({ api_key: payload['api_key'] })
        puts params
        RestClient.post(selldo_base_url + "/api/leads/create.json", params)
      end
    else
      puts payload
    end
  end

  def add_slot_details(lead, payload={})
    if payload.present?
      params = {}
      params['custom_slot_details'] = payload['slot_details'] if payload['slot_details'].present?
      params['custom_slot_status'] = payload['slot_status'] if payload['slot_status'].present?

      if params.present?
        custom_hash = {lead: params}
        sell_do(lead, custom_hash)
      end
    end
  end

  def sell_do(lead, data={})
    MixpanelPusherWorker.perform_async(lead.mixpanel_id, stage, {}) if current_client.mixpanel_token.present?

    selldo_base_url = ENV_CONFIG['selldo']['base_url'].chomp('/')
    if selldo_base_url.present? && lead.lead_id.present? && lead.project.selldo_api_key.present?
      params = {
        api_key: lead.project.selldo_api_key,
        client_id: lead.project.selldo_client_id,
        not_clear_custom_fields: true
      }
      params = params.merge(data)
      url = selldo_base_url + "/client/leads/#{lead.lead_id}.json"

      Rails.logger.info "[SelldoLeadUpdater][LeadPortalStage][INFO][Params] #{params}"
      Rails.logger.info "[SelldoLeadUpdater][LeadPortalStage][INFO][POST] #{url}"

      RestClient.put(url, params)
    end
  end

  def add_secondary_sales(lead, payload={})
    selldo_base_url = ENV_CONFIG['selldo']['base_url'].chomp('/')
    if selldo_base_url.present? && lead.project.selldo_api_key.present? && lead.project.selldo_client_id?
      if lead.lead_id.present? && payload['secondary_sale_ids'].present?
        params = {
          api_key: lead.project.selldo_api_key,
          client_id: lead.project.selldo_client_id,
          lead: {
            add_secondary_sale_ids: payload['secondary_sale_ids']
          }
        }
        puts params
        RestClient.put("#{selldo_base_url}/client/leads/#{lead.lead_id.to_s}.json", params)
      end
    end
  end

  def reassign_lead(lead, payload)
    selldo_base_url = ENV_CONFIG['selldo']['base_url'].chomp('/')
    if selldo_base_url.present? && lead.project.selldo_api_key.present? && lead.project.selldo_client_id?
      if lead.lead_id.present? && payload['sales_id'].present?
        params = {
          api_key: lead.project.selldo_api_key,
          client_id: lead.project.selldo_client_id,
          lead: {
            sales_id: payload['sales_id']
          }
        }
        puts params
        r = RestClient.put("#{selldo_base_url}/client/leads/#{lead.lead_id.to_s}.json", params)
      end
    end
  end
end
