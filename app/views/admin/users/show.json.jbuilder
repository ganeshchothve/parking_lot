json.user do
  json.partial! 'admin/users/show', user: @user
end
