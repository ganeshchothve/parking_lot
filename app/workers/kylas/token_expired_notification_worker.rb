module Kylas
  class TokenExpiredNotificationWorker
    include Sidekiq::Worker

    def perform
      User.ne(kylas_access_token: nil).each do |user|
        if !user.access_token_valid?
          user.send_marketplace_token_expired_email
        end
      end
    end
  end
end