module LeadsHelper

  def selldo_client_id(client = nil, project = nil)
    selldo_config_base(client, project).try(:selldo_client_id)
  end

  def selldo_form_id(client = nil, project = nil)
    selldo_config_base(client, project).try(:selldo_form_id)
  end

  def selldo_channel_partner_form_id(client = nil, project = nil)
    selldo_config_base(client, project).try(:selldo_channel_partner_form_id)
  end

  def selldo_gre_form_id(client = nil, project = nil)
    selldo_config_base(client, project).try(:selldo_gre_form_id)
  end

  def selldo_api_key(client = nil, project = nil)
    selldo_config_base(client, project).try(:selldo_api_key)
  end

  def selldo_config_base(client = nil, project = nil)
    if project.present? && project.selldo_client_id.present? && project.selldo_form_id.present? && project.selldo_gre_form_id.present? && project.selldo_channel_partner_form_id.present?
      project
    elsif client.present? && client.selldo_client_id.present? && client.selldo_form_id.present? && client.selldo_gre_form_id.present? && client.selldo_channel_partner_form_id.present?
      client
    end
  end

  def filter_cp_users_options(client=nil)
    User.in(role: %w(cp_owner channel_partner)).where(is_active: true, booking_portal_client_id: client.id, user_status_in_company: 'active').collect{|u| [u.ds_name, u.id]}
  end
end
