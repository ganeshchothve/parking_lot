class BulkJobObserver < Mongoid::Observer
  def after_save bulk_job
    if bulk_job.status_changed? && ['completed', 'partially_completed'].include?(bulk_job.status)
      Kylas::BulkJob::GenerateCSVWorker.perform_async(bulk_job.id)
    end
  end
end
