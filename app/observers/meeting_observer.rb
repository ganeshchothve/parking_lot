class MeetingObserver < Mongoid::Observer
  def before_save meeting
    if meeting.toggle_participant_id.present?
        toggle_participant_id = BSON::ObjectId(meeting.toggle_participant_id.to_s)
        if meeting.participant_ids.include?(toggle_participant_id)
            meeting.participant_ids.reject!{|x| x == toggle_participant_id}
        else
            meeting.participant_ids << toggle_participant_id
        end
    end
  end
end
