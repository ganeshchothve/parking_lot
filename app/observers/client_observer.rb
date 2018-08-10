class ClientObserver < Mongoid::Observer
  def before_create client
  end
  def after_save client
    DatabaseSeeds::SmsTemplate.seed client.id.to_s
  end
end
