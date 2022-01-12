class Crm::Api::Put < Crm::Api::Post
  METHODS = %w[put patch]

  field :http_method, type: String, default: 'put'

  def execute record
    _execute record, (http_method || 'put')
  end
end
