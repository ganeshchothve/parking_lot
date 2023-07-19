module LeadManagerHelper

  def custom_lead_managers_path
    current_user.buyer? ? '' : admin_lead_managers_path
  end
end
