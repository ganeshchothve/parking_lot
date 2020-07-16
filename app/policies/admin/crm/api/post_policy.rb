class Admin::Crm::Api::PostPolicy < Admin::Crm::ApiPolicy

  def permitted_attributes
    attributes = super
    attributes += %w[response_crm_id_location]
  end
end
