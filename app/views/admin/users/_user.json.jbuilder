if params[:ds]
  hash = {id: user.id, name: user.ds_name}
  json.extract! hash, :id, :name
else
  json.extract! user, :id, :name, :email, :phone, :created_at, :updated_at, :lead_id, :role
  json.url admin_user_url(user, format: :json)
end
