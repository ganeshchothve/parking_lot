class ApplicationMailer < ActionMailer::Base
  default from: 'info@embassysprings.com'
  layout 'mailer'

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
