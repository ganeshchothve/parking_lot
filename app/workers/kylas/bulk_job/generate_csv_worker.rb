class Kylas::BulkJob::GenerateCSVWorker
  include Sidekiq::Worker

  def perform(bulk_job_id)
    bulk_job = BulkJob.where(id: bulk_job_id).first
    if bulk_job.present?
      generate_success_records_csv(bulk_job)
      generate_failed_records_csv(bulk_job)
    end
  end

  def generate_success_records_csv(bulk_job)
    records = bulk_job.records.where(status: 'completed')
    if records.present?
      headers = ["Entity ID"]
      csv_data = CSV.generate do |csv|
        csv << headers
        records.each do |record|
          csv << [record.entity_id]
        end
      end

      File.open("#{bulk_job.id}_success_records.csv", "wb") do |file|
        file.write(csv_data)
        bulk_job.success_file = file
      end
      if bulk_job.save
        bulk_job.records.where(status: 'completed').delete_all
      end
    end
  end

  def generate_failed_records_csv(bulk_job)
    records = bulk_job.records.where(status: 'failed')
    if records.present?
      headers = ["Entity ID", "Partner ID", "Error Message"]
      csv_data = CSV.generate do |csv|
        csv << headers
        records.each do |record|
          csv << [record.entity_id, record.partner_id, record.error_message]
        end
      end

      File.open("#{bulk_job.id}_failed_records.csv", "wb") do |file|
        file.write(csv_data)
        bulk_job.failure_file = file
      end
      if bulk_job.save
        bulk_job.records.where(status: 'failed').delete_all
      end
    end
  end
end
