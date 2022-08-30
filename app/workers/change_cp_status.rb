class ChangeCpStatus
  include Sidekiq::Worker

  def perform(client_id, flag, field)
    client = Client.where(id: client_id).first
    if client
      if field.singularize == 'channel_partner'
        change_cp_status(flag)
      end
    end
  end

  def change_cp_status flag
    cp_users = User.in(role: User::CHANNEL_PARTNER_USERS)
    cp_users.each do |cp_user|
      cp_user.set(is_active: flag)
    end
  end
end