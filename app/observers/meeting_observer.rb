class MeetingObserver < Mongoid::Observer
  include ApplicationHelper

  def before_save meeting
    if meeting.toggle_participant_id.present?
        toggle_participant_id = BSON::ObjectId(meeting.toggle_participant_id.to_s)
        if meeting.participant_ids.include?(toggle_participant_id)
            meeting.participant_ids.reject!{|x| x == toggle_participant_id}
        else
            meeting.participant_ids << toggle_participant_id
        end
        user = User.where(id: toggle_participant_id).first
        if user && user.booking_portal_client.external_api_integration?
          if Rails.env.staging? || Rails.env.production?
            MeetingObserverWorker.perform_async(meeting.id.to_s, user.id.to_s, meeting.changes)
          else
            MeetingObserverWorker.new.perform(meeting.id, user.id, meeting.changes)
          end
        end
    end
  end

  #def before_create meeting
  #  if meeting.scheduled_on.present? && meeting.scheduled_on <= Time.now.beginning_of_day
  #    meeting.complete
  #  end
  #end
end
