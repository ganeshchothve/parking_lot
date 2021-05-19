class LeadObserver < Mongoid::Observer
  def before_validation lead
    lead.email = lead.email.downcase
    lead.phone = Phonelib.parse(lead.phone).to_s if lead.phone.present?
  end

  def after_create lead
    lead.send_create_notification
    Crm::Api::Post.where(resource_class: 'Lead', is_active: true).each do |api|
      api.execute(lead)
    end
  end

  def after_save lead
    if lead.lead_id_changed? && lead.lead_id.present? && crm = Crm::Base.where(domain: ENV_CONFIG.dig(:selldo, :base_url)).first
      lead.update_external_ids({ reference_id: lead.lead_id }, crm.id)
    end
  end

  def after_update lead
    # lead.send_update_notification if lead.stage_changed? && lead.stage.present?
  end
end
