class SiteVisitObserverWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'event'

  def perform(site_visit_id, action='create', changes={})
    sv = SiteVisit.where(id: site_visit_id).first
    if sv.present?
      client_id = sv.booking_portal_client_id
      lead = sv.lead
      project = sv.project
      manager = sv.manager
      if manager.present?
        sv_count = SiteVisit.filter_by_manager_id(manager.id).filter_by_is_revisit(false).count
        payload = {
          'site_visit' => sv.as_json(include: :notes),
          'project' => project.as_json,
          'lead' => lead.as_json(methods: [:name]),
          'manager' => manager.as_json(methods: [:name]),
          'sv_count' => sv_count
        }.merge(changes || {})

        users = User.or([{role: 'dev_sourcing_manager', project_ids: project.id.to_s, is_active: true}, {id: sv.manager_id, role: {'$in': %w(cp_owner channel_partner)}}]).where(booking_portal_client_id: client_id)
        users.each do |user|
          if action == 'create'

            Crm::Api::ExecuteWorker.perform_async('post', 'User', user.id, 'New Walkin Scheduled', payload)

          elsif action == 'update'

            if sv.status == 'scheduled' && changes.keys.include?('scheduled_on') && changes.dig('scheduled_on', 1).present?
              Crm::Api::ExecuteWorker.perform_async('post', 'User', user.id, 'Walkin Rescheduled', payload)
            end
            if changes.keys.include?('status') && changes.dig('status', 1) == 'conducted'
              Crm::Api::ExecuteWorker.perform_async('post', 'User', user.id, 'Walkin Conducted', payload)
            end
            if changes.keys.include?('approval_status') && changes.dig('approval_status', 1) == 'approved'
              Crm::Api::ExecuteWorker.perform_async('post', 'User', user.id, 'Walkin Approved', payload)
            end
            if changes.keys.include?('approval_status') && changes.dig('approval_status', 1) == 'rejected'
              Crm::Api::ExecuteWorker.perform_async('post', 'User', user.id, 'Walkin Rejected', payload)
            end

          end
        end
      end
    end
  end
end
