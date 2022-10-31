class ChangeCpStatus
  include Sidekiq::Worker

  def perform(client_id, field)
    client = Client.where(id: client_id).first
    field_status = client.send("enable_#{field}")
    if client
      if field.singularize == 'channel_partner'
        change_cp_status(field_status)
      end
    end
  end

  def change_cp_status status
    cp_users = User.in(role: User::CHANNEL_PARTNER_USERS)
    cp_users.each do |cp_user|
      cp_user.set(is_active: status)
    end
  end
end