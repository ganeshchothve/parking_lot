json.array! @leads do |lead|
  if params[:ds]
    hash = {id: lead.id, name: lead.ds_name}
    json.extract! hash, :id, :name
  else
    json.extract! lead, :id, :name, :email, :phone, :created_at, :updated_at
    json.url admin_lead_url(lead, format: :json)
  end
end
