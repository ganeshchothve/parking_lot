if params[:ds]
  hash = {id: channel_partner.id, name: channel_partner.ds_name}
  json.extract! hash, :id, :name
else
  json.extract! channel_partner, :id, :name, :email, :phone, :created_at, :updated_at
  json.url channel_partner_url(channel_partner, format: :json)
end
