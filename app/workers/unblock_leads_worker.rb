class UnblockLeadsWorker
  include Sidekiq::Worker

  def perform
    users = User.where(temporarily_blocked: true, unblock_at: Date.today)
    users.each do |user|
      user.unblock_lead!
    end
  end
end