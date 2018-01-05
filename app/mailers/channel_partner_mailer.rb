class ChannelPartnerMailer < ApplicationMailer
  default from: 'from@example.com'
  layout 'mailer'

  def send_create channel_partner_id
    @channel_partner = ChannelPartner.find(channel_partner_id)
  end

  def send_active channel_partner_id
    @channel_partner = ChannelPartner.find(channel_partner_id)
  end
end
