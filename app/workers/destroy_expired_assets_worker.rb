class DestroyExpiredAssetsWorker
  include Sidekiq::Worker

  def perform
    expired_assets = Asset.filter_by_expired_assets
    expired_assets.destroy_all
  end
end