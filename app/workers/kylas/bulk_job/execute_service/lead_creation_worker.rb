class Kylas::BulkJob::ExecuteService::LeadCreationWorker
  include Sidekiq::Worker

  def perform(bulk_job_id, entity_id)
    if bulk_job_id.present? && entity_id.present?
      bulk_job = BulkJob.where(id: bulk_job_id).first

      records = bulk_job.records.where(entity_id: entity_id, status: 'queued')
      records_count = records.count
      owner_id = records.first.entity_payload.dig(:ownerId).to_s
      project_id = bulk_job.payload.dig(:project_id)
      owner = User.where(booking_portal_client_id: bulk_job.booking_portal_client_id, kylas_user_id: owner_id).first
      user = create_user(records.first)

      if user.present?
        user.skip_confirmation_notification! if user.new_record?
        if (user.new_record? && user.save) || (user.persisted?)
          records.each do |record|
            record.update(status: 'in_progress')
            lead = user.leads.build
            lead.email = user.email
            lead.phone = user.phone
            lead.first_name = user.first_name
            lead.last_name = user.last_name
            lead.booking_portal_client_id = bulk_job.booking_portal_client_id
            lead.project_id = project_id
            lead.owner_id = owner.try(:id)
            lead.manager_id = record.partner_id
            lead.kylas_lead_id = record.entity_id
            if lead.save
              record.update(status: 'completed')
              update_lead_in_kylas(lead, record)
            else
              record.update(status: 'failed', error_message: lead.errors.full_messages.to_sentence)
            end
          end
        else
          records.update_all(status: 'failed', error_message: user.errors.full_messages.to_sentence)
        end
      else
        records.update_all(status: 'failed', error_message: 'Email or phone number is required')
      end
      bulk_job.inc(executed_records: records_count)
      if (bulk_job.total_records == bulk_job.executed_records)
        if bulk_job.records.where(status: 'failed').count > 0
          bulk_job.update(status: 'partially_completed')
        else
          bulk_job.update(status: 'completed')
        end
      end
    end
  end

  def create_user(record)
    email = record.entity_payload.dig(:emails, 0, :value)
    phone_data = record.entity_payload.dig(:phoneNumbers, 0)
    phone = (phone_data['dialCode'] + phone_data['value']) if phone_data.present?
    query = []
    query << {email: email} if email.present?
    query << {phone: phone} if phone.present?
    if query.present?
      user = User.or(query).where(booking_portal_client_id: record.booking_portal_client_id).first
      unless user.present?
        user = User.new
        user.email = email
        user.phone = phone
        user.first_name = record.entity_payload.dig(:firstName)
        user.last_name = record.entity_payload.dig(:lastName)
        user.booking_portal_client = record.booking_portal_client
        user.created_by = record.bulk_job.creator
        user
      else
        user
      end
    else
      return
    end
  end

  # update product on Lead if product not present on Lead
  # or
  # product is not same as kylas lead's product
  def update_lead_in_kylas(lead, record)
    Kylas::SyncLeadToKylasWorker.perform_async(lead.id.to_s)

    # Below code is related to attaching product to lead
    # TODO: Not required for now, Please check the implementation while uncommenting
    # products = record.entity_payload.dig('products')
    # kylas_product_id = lead.project.kylas_product_id
    # lead_params = {}
    # lead_params['lead'] = lead.as_json(only: [:id, :first_name, :last_name])
    # lead_params['lead']['kylas_product_id'] = kylas_product_id
    # lead_params = lead_params.with_indifferent_access
    # if (products.blank? || products.pluck('id').map(&:to_s).exclude?(kylas_product_id))
    #     response = Kylas::UpdateLead.new(lead.user, lead.kylas_lead_id, lead_params).call
    #     unless response[:success]
    #       record.update(status: 'failed', error_message: response[:error])
    #     end
    # end
  end


end
