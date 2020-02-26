class Admin::Crm::Api::GetPolicy < Admin::Crm::ApiPolicy

  def permitted_attributes
    attributes = super
    attributes += %w[response_data_location filter_hash response_decryption_key]
  end
end
