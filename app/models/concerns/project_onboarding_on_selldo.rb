require "uri"
require "json"
require "net/http"
module ProjectOnboardingOnSelldo
  extend ActiveSupport::Concern

  included do
    BASE_URL = ENV_CONFIG.dig(:selldo, :base_url).chomp('/')
  end

  def sync_on_selldo
    errors = []
    create_custom_field('portal stage', 'lead', errors)
    create_custom_field('partner code', 'lead', errors)
    create_custom_field('partner code', 'site_visit', errors)

    website_api_client = get_api_clients('IRIS with campaign response', errors).try(:[], 'results')&.first&.presence
    website_api_client = create_api_client('IRIS with campaign response', 'website', true, errors) unless website_api_client
    updator_api_client = get_api_clients('IRIS without campaign response', errors).try(:[], 'results')&.first&.presence
    updator_api_client = create_api_client('IRIS without campaign response', 'updator', false, errors) unless updator_api_client

    if website_api_client
      self.set(selldo_api_key: website_api_client['api_key'])
    end

    campaigns = get_campaigns(errors)
    if campaigns
      organic_campaign_id = campaigns['results'].find{|x| x['name'] == 'organic'}['_id']
      cp_campaign_id = campaigns['results'].find{|x| x['name'] == 'channel_partner'}['_id']
      sales_id = get_sales(errors)['results'].first['_id'] rescue nil
      if sales_id.present?
        address = {
          address1: self.address.try(:address1),
          address2: self.address.try(:address2),
          state: self.address.try(:state),
          country: self.address.try(:country),
          city: self.address.try(:city),
          zip: self.address.try(:zip),
          micro_market: self.micro_market,
          lat: self.lat,
          lng: self.lng,
        }
        # TODO: Replace Project name & other details
        project = create_project(self.name, nil, sales_id, 'possession', address, errors)

        if project.present?
          self.set(selldo_id: project['_id'])

          # TODO: Replace broker with iris
          if website_api_client.present?
            cp_srd = create_srd(cp_campaign_id, website_api_client, 'iris', '', project['_id'], errors)
            if cp_srd
              self.set(selldo_cp_srd: cp_srd['_id'])
            end
            organic_srd = create_srd(organic_campaign_id, website_api_client, 'iris', '', project['_id'], errors)
            if organic_srd
              self.set(selldo_default_srd: organic_srd['_id'])
            end
          else
            errors << 'Website API Client not present'
          end

          url = Rails.application.routes.url_helpers
          host = Rails.application.config.action_mailer.default_url_options[:host]
          port = Rails.application.config.action_mailer.default_url_options[:port].to_i
          host = (port == 443 ? 'https://' : 'http://') + host

          create_workflow("Site Visit Scheduled to IRIS", "sitevisit_scheduled", "site_visit#project_id", project['_id'], "SiteVisit", "#{host.chomp('/')}/sell_do/sitevisit_scheduled")

          create_workflow("Site Visit Conducted to IRIS", "sitevisit_conducted", "site_visit#project_id", project['_id'], "SiteVisit", "#{host.chomp('/')}/sell_do/sitevisit_conducted")

          create_workflow("New lead Created to IRIS", "new_lead", "lead_meta_info#project_ids", project['_id'], "LeadMetaInfo", "#{host.chomp('/')}/sell_do/lead_created")
        end
      end
    end
    errors
  end

  private

  def base_params
    {
      "user_token": ENV_CONFIG.dig(:selldo, :user_token),
      "user_email": ENV_CONFIG.dig(:selldo, :user_email),
      "client_id": self.selldo_client_id
    }
  end

  def create_workflow name, event, trigger_predicate, project_id, action_event_type, webhook_link
    url = URI("#{BASE_URL}/client/recipes.json")
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Post.new(url)
    request["Content-Type"] = "application/json"
    request.body = base_params.merge({
      "name": name,
      "description": name,
      "event": event,
      "is_active": true,
      "is_default": false
    }).to_json
    begin
      response = https.request(request)
      if response.code == '200' || response.code == '201'
        workflow = JSON.parse(response.body)
        url = URI("#{BASE_URL}/client/recipes/#{workflow['_id']}/branch.json")
        https = Net::HTTP.new(url.host, url.port)
        https.use_ssl = true
        request = Net::HTTP::Post.new(url)
        request["Content-Type"] = "application/json"
        request.body = base_params.merge({
          branch_type: "condition",
          delay: nil,
          depth_level: 1,
          recipe_id: workflow['_id'],
          match_all: true,
          no_children: 0,
          yes_children: 0
        }).to_json
        response = https.request(request)
        if response.code == '200' || response.code == '201'
          branch = JSON.parse(response.body)
          url = URI("#{BASE_URL}/client/recipes/#{workflow['_id']}/branch/#{branch['_id']}.json")
          https = Net::HTTP.new(url.host, url.port)
          https.use_ssl = true
          request = Net::HTTP::Put.new(url)
          request["Content-Type"] = "application/json"
          request.body = base_params.merge({
            branch_type: "condition",
            delay: nil,
            depth_level: 1,
            recipe_id: workflow['_id'],
            match_all: true,
            no_children: 0,
            triggers_attributes: [{
              operator: "in",
              predicate: trigger_predicate, #"site_visit#project_id"
              sub_value: "",
              value: project_id
            }],
            yes_children: 0
          }).to_json
          response = https.request(request)
          if response.code == '200' || response.code == '201'
            url = URI("#{BASE_URL}/client/recipes/#{workflow['_id']}/branch.json")
            https = Net::HTTP.new(url.host, url.port)
            https.use_ssl = true
            request = Net::HTTP::Post.new(url)
            request["Content-Type"] = "application/json"
            request.body = base_params.merge({
              branch_direction: "yes",
              branch_type: "action",
              delay: nil,
              recipe_id: workflow['_id'],
              depth_level: 2,
              match_all: true,
              no_children: 0,
              true_parent_id: branch['_id'],
              yes_children: 0
            }).to_json
            response = https.request(request)
            if response.code == '200' || response.code == '201'
              action_branch = JSON.parse(response.body)
              url = URI("#{BASE_URL}/client/recipes/#{workflow['_id']}/branch/#{action_branch['_id']}.json")
              https = Net::HTTP.new(url.host, url.port)
              https.use_ssl = true
              request = Net::HTTP::Put.new(url)
              request["Content-Type"] = "application/json"
              request.body = base_params.merge({
                actions_attributes: [{
                  action_type: "webhook",
                  event_type: action_event_type, # "SiteVisit"
                  recipe_id: workflow['_id'],
                  request_type: "post",
                  url: webhook_link,
                  _type: "WebhookAction"
                }]
              }).to_json
              response = https.request(request)
              if response.code == '200' || response.code == '201'
                return JSON.parse(response.body)
              else
                puts response.body
                return nil
              end
            else
              puts response.body
              return nil
            end
          else
            puts response.body
            return nil
          end
        else
          puts response.body
          return nil
        end
      else
        puts response.body
        return nil
      end
    rescue => e
      puts e.message
      return nil
    end
  end

  def create_project name, developer_id, sales_id, possession, address, errors
    url = URI("#{BASE_URL}/client/projects.json")
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Post.new(url)
    request["Content-Type"] = "application/json"
    request.body = base_params.merge({
      "project": {
        name: name,
        developer_id: developer_id,
        description: name + ' Details',
        project_sale_ids: sales_id,
        possession: possession,
        address_attributes:{
          address1: address[:address1],
          address2: address[:address2],
          country: address[:country],
          state: address[:state],
          city: address[:city],
          zip: address[:zip]
        },
        micro_market: address[:micro_market],
        lat: address[:lat],
        lng: address[:lng]
      }
    }).to_json
    begin
      response = https.request(request)
      if response.code == '200' || response.code == '201'
        return JSON.parse(response.body)
      else
        errors << "Create Project - ERRMSG: #{response.body}"
        return nil
      end
    rescue => e
      errors << "Create Project - ERRMSG: #{e.message}"
      return nil
    end
  end

  def create_srd campaign_id, api_client, source, sub_source, project_id, errors
    url = URI("#{BASE_URL}/rules.json")
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Post.new(url)
    request["Content-Type"] = "application/json"
    request.body = base_params.merge({
      "rule": {
        "entity_type": 'ApiClient',
        "entity_id": api_client['_id'],
        "entity_value": api_client['api_client_type'],
        "campaign_api_rule_id": campaign_id,
        "source": source,
        "sub_source": sub_source,
        'project_id': project_id
      }
    }).to_json
    begin
      response = https.request(request)
      if response.code == '200' || response.code == '201'
        return JSON.parse(response.body)
      else
        errors << "Create SRD - ERRMSG: #{response.body}"
        return nil
      end
    rescue => e
      errors << "Create SRD - ERRMSG: #{e.message}"
      return nil
    end
  end

  def get_sales errors
    search_params = {
      status: true,
      department: 'sales',
      role: 'sales'
    }
    url = URI("#{BASE_URL}/client/users.json?#{base_params.to_param}&#{search_params.to_param}")
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Get.new(url)
    request["Content-Type"] = "application/json"
    begin
      response = https.request(request)
      if response.code == '200' || response.code == '201'
        return JSON.parse(response.body)
      else
        errors << "Fetch Sales - ERRMSG: #{response.body}"
        return nil
      end
    rescue => e
      errors << "Fetch Sales - ERRMSG: #{e.message}"
      return nil
    end
  end

  def get_developers
    url = URI("#{BASE_URL}/client/developers.json?#{base_params.to_param}")
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Get.new(url)
    request["Content-Type"] = "application/json"
    begin
      response = https.request(request)
      if response.code == '200' || response.code == '201'
        return JSON.parse(response.body)
      else
        puts response.body
        return nil
      end
    rescue => e
      puts e.message
      return nil
    end
  end

  def get_api_clients name, errors
    url = URI("#{BASE_URL}/client/api_clients.json?#{base_params.to_param}&name=#{name}")
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Get.new(url)
    request["Content-Type"] = "application/json"
    begin
      response = https.request(request)
      if response.code == '200' || response.code == '201'
        return JSON.parse(response.body)
      else
        errors << "Fetch API Clients - ERRMSG: #{response.body}"
        return nil
      end
    rescue => e
      errors << "Fetch API Clients - ERRMSG: #{e.message}"
      return nil
    end
  end

  def get_campaigns errors
    url = URI("#{BASE_URL}/client/campaigns.json?#{base_params.to_param}")
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Get.new(url)
    request["Content-Type"] = "application/json"
    begin
      response = https.request(request)
      if response.code == '200' || response.code == '201'
        return JSON.parse(response.body)
      else
        errors << "Fetch Campaings - ERRMSG: #{response.body}"
        return nil
      end
    rescue => e
      errors << "Fetch Campaings - ERRMSG: #{e.message}"
      return nil
    end
  end

  def create_api_client name, api_client_type, allow_reengaged, errors
    url = URI("#{BASE_URL}/client/api_clients.json")
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Post.new(url)
    request["Content-Type"] = "application/json"
    request.body = base_params.merge({
      "api_client": {
        "name": name,
        "api_client_type": api_client_type,
        "allow_reengaged": allow_reengaged
      }
    }).to_json
    begin
      response = https.request(request)
      if response.code == '200' || response.code == '201'
        return JSON.parse(response.body)
      else
        errors << "Create API Client - #{name} - #{api_client_type} - ERRMSG: #{response.body}"
        return nil
      end
    rescue => e
      errors << "Create API Client - #{name} - #{api_client_type} - ERRMSG: #{e.message}"
      return nil
    end
  end

  def create_custom_field label, class_type, errors
    url = URI("#{BASE_URL}/client/configuration/custom_fields.json")
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Post.new(url)
    request["Content-Type"] = "application/json"
    request.body = base_params.merge({
      "custom_field": {
        "label": label,
        "class_type": class_type,
        "field_type": "text",
        "required": false,
        "active": true,
        "hide_on_form": true
      }
    }).to_json
    begin
      response = https.request(request)
      if response.code == '200' || response.code == '201'
        return JSON.parse(response.body)
      else
        errors << "Create Custom Field - ERRMSG: #{response.body}"
        return nil
      end
    rescue => e
      errors << "Create Custom Field - ERRMSG: #{e.message}"
      return nil
    end
  end
end
