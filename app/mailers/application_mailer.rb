class ApplicationMailer < ActionMailer::Base
  default from: "Embassy Springs <no-reply@embassysprings.com>"
  layout 'mailer'
  helper ApplicationHelper

  def crm_team
    # TODO: Implement this with default cc - Embassy CRM Team
    []
  end

  def default_team
    # TODO: Implement this with default cc - Embassy CRM Team
    []
  end

  def channel_partner_management_team
    # TODO: Implement this with default cc - Embassy CRM Team
    []
  end
end
