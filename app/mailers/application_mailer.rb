class ApplicationMailer < ActionMailer::Base
  default from: "Embassy Edge <no-reply@embassyedge.com>"
  layout 'mailer'
  helper ApplicationHelper

  def crm_team
    # TODO: Implement this with default cc - Embassy CRM Team
    ["supriya@amuratech.com"]
  end

  def default_team
    # TODO: Implement this with default cc - Embassy CRM Team
    ["supriya@amuratech.com"]
  end

  def channel_partner_management_team
    # TODO: Implement this with default cc - Embassy CRM Team
    ["supriya@amuratech.com"]
  end
end
