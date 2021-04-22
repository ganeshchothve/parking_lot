module ChannelPartnersHelper

  def custom_channel_partners_path
    [ChannelPartner]
  end

  def available_chanel_partner_statuses channel_partner
    if channel_partner.new_record?
      [ 'inactive' ]
    else
      statuses = channel_partner.aasm.events(permitted: true).collect{|x| x.name.to_s}
    end
  end
end
