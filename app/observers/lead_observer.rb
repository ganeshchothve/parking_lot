class LeadObserver < Mongoid::Observer
  def before_validation lead
    lead.email = lead.email&.downcase
    lead.phone = Phonelib.parse(lead.phone).to_s if lead.phone.present?
    lead.channel_partner_id = lead.manager&.channel_partner_id if lead.channel_partner_id.blank? && lead.manager.present?
    lead.owner_id = Crm::Base.where(domain: ENV_CONFIG.dig(:kylas, :base_url), booking_portal_client_id: lead.booking_portal_client.id).first.try(:user_id) if lead.owner_id.blank? && lead.booking_portal_client.try(:is_marketplace?)
  end

  def after_create lead
    lead.third_party_references.each(&:update_references)
    lead.send_create_notification
  end

  def before_save lead
    if lead.closing_manager_id_changed? && lead.closing_manager_id.present?
      lead.assign_sales!(lead.closing_manager_id)
    end
  end

  def after_save lead
    if lead.lead_id_changed? && lead.lead_id.present?
      lead.user.set(lead_id: lead.lead_id) if lead.user.lead_id.blank?
      if crm = Crm::Base.where(booking_portal_client_id: lead.booking_portal_client_id, domain: ENV_CONFIG.dig(:selldo, :base_url)).first
        lead.update_external_ids({ reference_id: lead.lead_id }, crm.id)
      end
    end
    lead.calculate_incentive if lead.project.incentive_calculation_type?("calculated") && lead.project&.invoicing_enabled?
    lead.move_invoices_to_draft

    if lead.manager_id_changed? && lead.manager_id.present? && lead.booking_portal_client.is_marketplace? && lead.crm_reference_id(ENV_CONFIG.dig(:kylas, :base_url)).present?
      Kylas::DealUpdate.new(lead.user, lead, {run_in_background: false}).call
    end
  end

  def after_update lead
    # lead.send_update_notification if lead.stage_changed? && lead.stage.present?
  end
end
