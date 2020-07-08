module CrmIntegration
  extend ActiveSupport::Concern

  included do
    field :crm_id
  end

  def resource_name
  end

end