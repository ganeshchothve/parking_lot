class MeetingObserverWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'event'

  def perform(meeting_id, user_id, changes={})
    meeting = Meeting.where(id: meeting_id).first
    onesignal_base = Crm::Base.where(domain: ENV_CONFIG.dig(:onesignal, :base_url)).first
    if meeting.present?
      user = User.where(id: user_id).first
      if user && user.role.in?(%w(cp_owner channel_partner))
        payload = {
          'project' => meeting.project&.as_json,
          'campaign' => meeting.campaign&.as_json,
          'meeting' => meeting.as_json(include: :assets)
        }.merge(changes || {})

        if changes.present? && changes.has_key?('participant_ids')
          event_name = changes.dig('participant_ids', 1)&.map(&:to_s)&.include?(user.id.to_s) ? 'Event Subscribed' : 'Event Unsubscribed'
          Crm::Api::ExecuteWorker.perform_async('post', 'User', user.id, event_name, payload)
        end
      end
    end
  end
end
