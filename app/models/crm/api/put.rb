class Crm::Api::Put < Crm::Api::Post

  field :response_crm_id_location, type: String

  validates :response_crm_id_location, format: {with: /\A[a-zA-Z0-9_..]*\z/}, allow_blank: true

  def execute record
    _execute record, 'put'
  end
end
