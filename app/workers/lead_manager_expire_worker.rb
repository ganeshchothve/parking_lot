class LeadManagerExpireWorker
  include Sidekiq::Worker

  def perform
    Client.each do |client|
      LeadManager.where(booking_portal_client_id: client.id).active.lt(expiry_date: Date.current).each(&:expire!)
    end
  end
end
