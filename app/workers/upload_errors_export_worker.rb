class UploadErrorsExportWorker
  include Sidekiq::Worker

  def perform user_id, bulk_upload_report_id
    user = User.where(id: user_id).first
    bulk_upload_report = BulkUploadReport.where(id: bulk_upload_report_id).first

    file_name = "upload-errors-#{SecureRandom.hex}.csv"
    if user && bulk_upload_report
      correct_headers = Object.const_get("BulkUpload::#{bulk_upload_report.asset.try(:document_type).try(:classify)}").new(bulk_upload_report).correct_headers
      CSV.open(Rails.root.join('exports', file_name), 'w+b') do |csv|
        csv << correct_headers
        bulk_upload_report.upload_errors.each do |error|
          csv << (error.row + error.messages)
        end
      end
    end
    ExportMailer.notify(file_name , user.email, "#{bulk_upload_report.asset.try(:document_type)}").deliver
  end

end