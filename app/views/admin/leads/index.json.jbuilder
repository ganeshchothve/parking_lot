json.array! @leads do |lead|
  if params[:ds]
    hash = {id: lead.id, name: lead.ds_name(current_user), search_name: lead.search_name}
    json.extract! hash, :id, :name, :search_name
  else
    json.extract! lead, :id, :name, :email, :phone, :created_at, :updated_at
    json.url admin_lead_url(lead, format: :json)
  end
end
