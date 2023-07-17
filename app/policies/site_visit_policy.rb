class SiteVisitPolicy < ApplicationPolicy
  def permitted_attributes params={}
    attributes = [notes_attributes: NotePolicy.new(user, Note.new).permitted_attributes]
    attributes += [:project_id, :user_id, :lead_id, :creator_id, :created_by] if record.new_record?
    attributes += [:scheduled_on] if record.status == 'scheduled' || record.approval_status == 'rejected'
    attributes += [:conducted_on] if ['scheduled', 'missed', 'pending'].include?(record.status)
    attributes += [third_party_references_attributes: ThirdPartyReferencePolicy.new(user, ThirdPartyReference.new).permitted_attributes]
    attributes
  end
end
