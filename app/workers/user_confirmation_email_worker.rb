class UserConfirmationEmailWorker
  include Sidekiq::Worker

  def perform(user_id)
    user = User.where(id: user_id).first
    user._send_confirmation_instruction if user
  end
end