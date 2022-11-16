class LeadObserver < Mongoid::Observer
  def before_validation lead
    lead.email = lead.email&.downcase
    lead.phone = Phonelib.parse(lead.phone).to_s if lead.phone.present?
    lead.channel_partner_id = lead.manager&.channel_partner_id if lead.channel_partner_id.blank? && lead.manager.present?
  end

  def after_create lead
    lead.third_party_references.each(&:update_references)
    lead.send_create_notification
    if lead.booking_portal_client.kylas_tenant_id.present? && lead.crm_reference_id(ENV_CONFIG.dig(:kylas, :base_url)).blank?
      Kylas::CreateDeal.new(lead.user, lead, {run_in_background: false}).call
    end
  end

  def before_save lead
    if lead.closing_manager_id_changed? && lead.closing_manager_id.present?
      lead.assign_sales!(lead.closing_manager_id)
    end
  end

  def after_save lead
    if lead.lead_id_changed? && lead.lead_id.present? && crm = Crm::Base.where(domain: ENV_CONFIG.dig(:selldo, :base_url)).first
      lead.update_external_ids({ reference_id: lead.lead_id }, crm.id)
    end
    lead.calculate_incentive if lead.project.incentive_calculation_type?("calculated") && lead.project&.invoicing_enabled?
    lead.move_invoices_to_draft
  end

  def after_update lead
    # lead.send_update_notification if lead.stage_changed? && lead.stage.present?
  end
end
