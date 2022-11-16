class Crm::Api::Put < Crm::Api::Post
  METHODS = %w[put patch]

  field :http_method, type: String, default: 'put'

  def execute record, user=nil
    _execute record, user, (http_method || 'put')
  end
end
