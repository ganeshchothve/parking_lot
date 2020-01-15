class InventoryUploadWorker
  include Sidekiq::Worker

  def perform current_client_id, bulk_upload_report_id
    BulkUpload::Inventory.upload(current_client_id, bulk_upload_report_id)
  end
end
