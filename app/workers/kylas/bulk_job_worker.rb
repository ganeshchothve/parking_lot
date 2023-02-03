# TODO: generic way to call worker BulkJobWorker.perform_async(bulk_job_id)
class Kylas::BulkJobWorker
  include Sidekiq::Worker

  def perform(bulk_job_id)

    bulk_job = BulkJob.where(id: bulk_job_id).first
    if bulk_job.present?
      bulk_job.update(status: 'in_progress')
      entity_type = bulk_job.entity_type
      begin
        "Kylas::BulkJob::RecordsCreateService::#{entity_type}".constantize.new(bulk_job_id).call
      rescue => exception
        bulk_job.update(status: 'failed', failed_response: [exception.message])
      end
    end
  end


end
