json.user do
  json.partial! 'admin/users/show', user: @channel_partner.primary_user
end
