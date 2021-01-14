module ChannelPartnersHelper

  def custom_channel_partners_path
    [ChannelPartner]
  end

  def available_chanel_partner_statuses channel_partner
    if channel_partner.new_record?
      [ 'active' ]
    else
      statuses = ChannelPartner::STATUS
    end
  end
end
