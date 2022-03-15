json.current_page @channel_partners.current_page
json.per_page @channel_partners.per_page
json.total_entries @channel_partners.total_entries
json.entries @channel_partners, partial: 'channel_partners/channel_partner', as: :channel_partner
