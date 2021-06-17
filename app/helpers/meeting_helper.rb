module MeetingHelper
  def custom_meetings_path
    current_user.buyer? ? buyer_meetings_path : admin_meetings_path
  end

  def available_meeting_statuses meeting
    if meeting.new_record?
      [ 'draft' ]
    else
      statuses = meeting.aasm.events(permitted: true).collect{|x| x.name.to_s}
    end
  end
end