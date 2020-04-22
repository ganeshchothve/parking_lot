class BulkUploadWorker
  include Sidekiq::Worker

  def perform bulk_upload_report_id
    bur = BulkUploadReport.where(id: bulk_upload_report_id).first
    if bur
      Object.const_get("BulkUpload::#{bur.asset.try(:document_type).try(:classify)}").new(bur).upload
    end
  end
end
