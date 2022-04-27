class RemoveFileFromDatabaseWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'event'

  def perform(asset_id)
    co_branded_assets = Asset.where(parent_asset_id: asset_id, document_type: 'co_branded_asset').destroy_all
  end
end