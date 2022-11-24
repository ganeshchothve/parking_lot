require 'spreadsheet'
class SyncKylasUsersWorker
  include Sidekiq::Worker

  def perform client_id
    client = Client.where(id: client_id).first
    if client.present?
      client.set(sync_user: false)
      kylas_users = Kylas::FetchUsers.new(User.new(booking_portal_client: client)).call
      if kylas_users.present?
        kylas_users.each do |kylas_user|
          mp_user = find_user_in_iris(kylas_user[4].to_s, client_id)
          if !mp_user.present?
            user = User.new(
              first_name: kylas_user[0],
              last_name: kylas_user[1],
              email: kylas_user[2],
              phone: kylas_user[3]['dialCode'] + kylas_user[3]['value'],
              role: "sales",
              kylas_user_id: kylas_user[4].to_s,
              is_active_in_kylas: kylas_user[5],
              booking_portal_client: client
            )
            user.skip_confirmation_notification!
            user.save
          else
            mp_user.assign_attributes(
              first_name: kylas_user[0],
              last_name: kylas_user[1],
              email: kylas_user[2],
              phone: kylas_user[3]['dialCode'] + kylas_user[3]['value'],
              is_active_in_kylas: kylas_user[5]
            )
            mp_user.skip_confirmation_notification!
            mp_user.save
            mp_user.confirm if mp_user.unconfirmed_email.present?
          end
        end
      end
      client.set(sync_user: true)
    end
  end

  def find_user_in_iris(kylas_user_id, client_id)
    User.where(kylas_user_id: kylas_user_id, booking_portal_client_id: client_id).first
  end
end
