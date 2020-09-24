class ApiLog
  include Mongoid::Document
  include Mongoid::Timestamps
  extend FilterByCriteria

  field :request, type: Hash
  field :request_url, type: String
  field :response, type: Hash
  field :status, type: String
  field :message, type: String

  belongs_to :crm_api, class_name: 'Crm::Api'
  belongs_to :resource, polymorphic: true

  default_scope -> { desc(:created_at) }
  scope :filter_by_resource_id, ->(_resource_id) { where(resource_id: _resource_id) }
  scope :filter_by_status, ->(_status) { where(status: _status) }

end