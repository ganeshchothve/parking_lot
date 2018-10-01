module SFDC
  class Base

    def initialize
      response = get_token
      @access_token = response["access_token"]
      @instance_url = response["instance_url"]
    end

    def self.sfdc_date_format(date, with_time=false)
      return nil unless (date.is_a?(Date) || date.is_a?(Time)) && date.present?

      if with_time
        date.strftime("%Y-%m-%d %H:%M:%S")
      else
        date.strftime("%Y-%m-%d")
      end
    end

    def push(uri, data={})
      url = @instance_url + uri
      response = RestClient.post(url, data.to_json, { content_type: :json, accept: :json , authorization: "Bearer #{@access_token}"})
      JSON.parse(response.body) rescue response
    end

    # Deprecated
    # sync_sfdc true means that we require to sync again.
    def self.update_sync_status(response, client, options={})
      if response["status"] == "Success"
        success_ids = response["SuccessIds"].split(",")
        update_collection_data(success_ids, false, client, options)
      elsif response["status"] == "Failed"
        failed_lead_ids = response["FailedIds"].split(",")
        update_collection_data(failed_lead_ids, true, client)
      elsif response["status"] == "Partial"
        failed_lead_ids = response["FailedIds"].split(",")
        update_collection_data(failed_lead_ids, true, client)

        success_ids = response["SuccessIds"].split(",")
        update_collection_data(success_ids, false, client)
      end
      "OK"
    end

    def self.update_collection_data(collection_ids, status, client, options)
      matcher = { client_id: client.id }
      klass = options[:class_type].constantize
      if options[:class_type] == "Lead"
        lead_ids = client.leads.where(lead_id: { "$in" => collection_ids }).pluck(:id)
        klass = LeadMetaInfo
        matcher[:lead_id] = { "$in" => lead_ids }
      else
        matcher[:id] = { "$in" => collection_ids }
      end
      klass.where(matcher).update_all("sync_sfdc" => status, "sync_sfdc_on" => Time.now)
    end


    private

    def get_token
      url = ENV_CONFIG['sfdc']['url']
      client_id = ENV_CONFIG['sfdc']['client_id']
      client_secret = ENV_CONFIG['sfdc']['client_secret']
      username = ENV_CONFIG['sfdc']['username']
      password = ENV_CONFIG['sfdc']['password']

      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(uri.request_uri)
      request.set_form_data(
        "grant_type" => "password",
        "client_id" => client_id,
        "client_secret" => client_secret,
        "username" => username,
        "password" => password
      )
      response = http.request(request)
      JSON.parse(response.body)
    end
  end
end
