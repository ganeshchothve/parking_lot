class InterestedProjectObserverWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'event'

  def perform(interested_project_id, changes={})
    ip = InterestedProject.where(id: interested_project_id).first
    if ip.present?
      user = ip.user
      project = ip.project

      Crm::Api::ExecuteWorker.perform_async('post', 'User', user.id, nil, {
        'interested_projects' => Project.in(id: user.interested_projects.collect(&:project_id)).pluck(:name)
      })
      Crm::Api::ExecuteWorker.perform_async('post', 'User', user.id, 'Project Subscribed', { 'project' => project.as_json(methods: [:logo_url, :mobile_logo_url, :cover_photo_url, :mobile_cover_photo_url]) })
    end
  end
end
