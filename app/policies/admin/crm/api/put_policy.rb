class Admin::Crm::Api::PutPolicy < Admin::Crm::Api::PostPolicy
  def permitted_attributes
    attributes = super
    attributes += %w[http_method]
  end
end
