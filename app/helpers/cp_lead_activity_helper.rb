module CpLeadActivityHelper

  def custom_cp_lead_activities_path
    current_user.buyer? ? '' : admin_cp_lead_activities_path
  end
end