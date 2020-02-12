class Crm::Api
  include Mongoid::Document

  REQUEST_TYPES = %w[get post]

  field :resource_class, type: String
  field :path, type: String
  field :request_payload, type: String
  field :request_type, type: String

  belongs_to :base, foreign_key: :crm_id

  def execute
    process_request
  end
end
