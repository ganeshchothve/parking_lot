json.user do
  json.partial! 'admin/users/show', user: @user
end
json.message 'Registration request sent to Company owner'
