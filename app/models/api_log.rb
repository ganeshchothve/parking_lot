class ApiLog
  include Mongoid::Document
  include Mongoid::Timestamps
  extend FilterByCriteria

  LOG_TYPES = ["API", "Webhook"]

  field :request, type: Array
  field :request_url, type: String
  field :response, type: Array
  field :response_type, type: String
  field :status, type: String
  field :message, type: String
  field :log_type, type: String, default: "API"

  belongs_to :booking_portal_client, class_name: 'Client'
  belongs_to :crm_api, class_name: 'Crm::Api', optional: true
  belongs_to :resource, polymorphic: true

  default_scope -> { desc(:created_at) }
  scope :filter_by_resource_id, ->(_resource_id) { where(resource_id: _resource_id) }
  scope :filter_by_log_type, ->(_log_type) { where(log_type: _log_type) }
  scope :filter_by_status, ->(_status) { where(status: _status) }


  class << self

    def user_based_scope user, params = {}
      if user.role?(:superadmin)
        custom_scope = {  }
      else
        custom_scope = {  }
      end
      custom_scope.merge!({booking_portal_client_id: user.booking_portal_client.id})
      custom_scope
    end

    def log_responses(request_url, request, response, resource, response_type, booking_portal_client, status = nil, message = nil, log_type = "API")
      api_log = ApiLog.new
      api_log.assign_attributes(request_url: request_url, request: request, response: response, resource: resource, response_type: response_type, booking_portal_client: booking_portal_client, status: status, message: message, log_type: log_type)
      api_log.save
    end

  end


end
