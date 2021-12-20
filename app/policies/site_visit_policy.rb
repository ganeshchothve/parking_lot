class SiteVisitPolicy < ApplicationPolicy
  def permitted_attributes params={}
    attributes = [notes_attributes: NotePolicy.new(user, Note.new).permitted_attributes]
    attributes += [:project_id, :user_id, :lead_id, :creator_id] if record.new_record?
    attributes += [:scheduled_on] if record.status == 'scheduled'
    attributes += [:conducted_on] if ['scheduled', 'missed', 'pending'].include?(record.status)
    attributes
  end
end
