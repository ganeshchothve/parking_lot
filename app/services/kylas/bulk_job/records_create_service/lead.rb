# Record Create service
class Kylas::BulkJob::RecordsCreateService::Lead < Kylas::BulkJob::RecordsCreateService
  def create_records(response)
    partner_ids = bulk_job.payload['manager_ids']
    response.each do |data|
      entity_id = data.dig(:id).to_s
      partner_ids.each do |partner_id|
        if bulk_job.records.where(entity_id: entity_id, partner_id: partner_id).blank?
          record = bulk_job.records.build(booking_portal_client_id: bulk_job.booking_portal_client_id)
          record.entity_id = entity_id
          record.partner_id = partner_id
          record.entity_payload = data
          unless record.save
            bulk_job.update(status: 'failed', failed_response: [record.errors.full_messages])
            break
          end
        end
      end
      # if any record is not saved then break the loop
      break if bulk_job.status == 'failed'

      if bulk_job.status != 'failed' && bulk_job.records.where(entity_id: entity_id, status: 'queued').present?
        bulk_job.inc(total_records: partner_ids.count)
        execute_worker = bulk_job.execute_worker
        begin
          # TODO: Handle execution with sidekiq job id, only exucute if same instance is not present in sidekiq
          "Kylas::BulkJob::ExecuteService::#{execute_worker}".constantize.perform_async(bulk_job_id.to_s, entity_id.to_s)
        rescue => exception
          bulk_job.update(status: 'failed', failed_response: [exception.message])
          break
        end
      end
    end
  end

  def fetch_responses_page_wise_records_creations(response)
    response = response.with_indifferent_access
    pages = response.dig(:data, :totalPages)
    content = response.dig(:data, :content)
    create_records(content)
    count = 1
    while count < pages
      response = fetch_data({page_number: count})
      if response.present? && response[:success]
        response = response.with_indifferent_access
        content = response.dig(:data, :content)
        create_records(content)
      else
        bulk_job.update(status: 'failed', failed_response: [response[:errors]])
        break
      end
      count += 1
    end
  end
end
