json.message find_message(:signed_in)
json.user do
  json.partial! 'admin/users/show', user: resource
end
