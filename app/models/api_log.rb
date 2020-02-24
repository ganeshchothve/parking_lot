class ApiLog
  include Mongoid::Document
  include Mongoid::Timestamps

  field :request, type: Hash
  field :request_url, type: String
  field :response, type: Hash
  field :status, type: String

  belongs_to :crm_api, class_name: 'Crm::Api'
  belongs_to :resource, polymorphic: true

end