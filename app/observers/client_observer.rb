class ClientObserver < Mongoid::Observer
  def after_save client
    DatabaseSeeds::SmsTemplate.seed client.id.to_s
  end
end
