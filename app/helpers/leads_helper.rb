module LeadsHelper

  def selldo_client_id(project = nil)
    selldo_config_base(project).try(:selldo_client_id)
  end

  def selldo_form_id(project = nil)
    selldo_config_base(project).try(:selldo_form_id)
  end

  def selldo_channel_partner_form_id(project = nil)
    selldo_config_base(project).try(:selldo_channel_partner_form_id)
  end

  def selldo_gre_form_id(project = nil)
    selldo_config_base(project).try(:selldo_gre_form_id)
  end

  def selldo_api_key(project = nil)
    selldo_config_base(project).try(:selldo_api_key)
  end

  def selldo_config_base(project = nil)
    if project.present? && project.selldo_client_id.present? && project.selldo_form_id.present? && project.selldo_gre_form_id.present? && project.selldo_channel_partner_form_id.present?
      project
    elsif current_client.selldo_client_id.present? && current_client.selldo_form_id.present? && current_client.selldo_gre_form_id.present? && current_client.selldo_channel_partner_form_id.present?
      current_client
    end
  end
end
