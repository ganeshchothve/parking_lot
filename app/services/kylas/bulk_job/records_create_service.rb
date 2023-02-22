
class Kylas::BulkJob::RecordsCreateService
  attr_reader :bulk_job_id, :bulk_job

  def initialize(bulk_job_id)
    @bulk_job_id = bulk_job_id
    @bulk_job = BulkJob.where(id: bulk_job_id).first
  end

  def call
    unless bulk_job.present? && bulk_job.payload['manager_ids'].present? && bulk_job.payload['project_id'].present?
      bulk_job.update(status: 'failed', failed_response: ['Manager Ids or Project Id is missing in payload'])
      return
    end
    response = fetch_data
    if response.present? && response[:success]
      response = response.with_indifferent_access
      fetch_responses_page_wise_records_creations(response)
    else
      bulk_job.update(status: 'failed', failed_response: [response[:errors]])
    end
  end

  def fetch_data(data = {page_number: 0})
    user = bulk_job.creator || Crm::Base.where(domain: ENV_CONFIG.dig(:kylas, :base_url), booking_portal_client_id: bulk_job.booking_portal_client_id).first.try(:user)
    options = {}
    options[:page_number] = data[:page_number]
    options[:page_size] = 50
    options[:fields] = bulk_job.required_fields
    options[:request_payload] = bulk_job.entities_filter_payload
    api_service = "Kylas::Fetch#{bulk_job.entity_type.pluralize}".constantize
    response = api_service.new(user, options).call
    response
  end

end
