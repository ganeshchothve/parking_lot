json.current_page @site_visits.current_page
json.per_page @site_visits.per_page
json.total_entries @site_visits.total_entries

json.entries @site_visits do |site_visit|
  json.extract! site_visit, :_id, :approval_status, :status, :channel_partner_id, :conducted_by, :conducted_on, :cp_admin_id, :cp_code, :cp_manager_id, :created_at, :creator_id, :incentive_generated, :is_revisit, :lead_id, :manager_id, :project_id, :queue_number, :revisit_queue_number, :sales_id, :scheduled_on, :selldo_id, :site_visit_type, :time_slot_id, :user_id, :name
  if site_visit.rejection_reason.present?
    json.rejection_reason I18n.t("mongoid.attributes.site_visit/rejection_reason.#{site_visit.rejection_reason}")
  else
    json.rejection_reason nil
  end

  # Policies for mobile app
  json.allow_reschedule allow_reschedule?(site_visit)
  json.allow_state_change allow_state_change?(site_visit)
  json.allow_add_notes allow_add_notes?(site_visit)

  json.lead do
    json.name site_visit.lead.name
    json.email site_visit.lead.email
    json.phone site_visit.lead.phone
  end
end
