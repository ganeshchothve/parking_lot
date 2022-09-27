json.user do
  json.partial! 'admin/users/show', user: @user
end
json.message I18n.t("controller.channel_partners.register_request_sent")
