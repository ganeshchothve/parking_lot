class DestroyExpiredAssetsWorker
  include Sidekiq::Worker
    sidekiq_options queue: 'event'

  def perform
    expired_assets = Asset.filter_by_expired_assets
    expired_assets.destroy_all
  end
end