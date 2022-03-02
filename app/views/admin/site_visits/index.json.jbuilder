json.current_page @site_visits.current_page
json.per_page @site_visits.per_page
json.total_entries @site_visits.total_entries

json.entries @site_visits do |site_visit|
  json.extract! site_visit, :_id, :approval_status, :status, :channel_partner_id, :conducted_by, :conducted_on, :cp_admin_id, :cp_code, :cp_manager_id, :created_at, :creator_id, :incentive_generated, :is_revisit, :lead_id, :manager_id, :project_id, :queue_number, :rejection_reason, :revisit_queue_number, :sales_id, :scheduled_on, :selldo_id, :site_visit_type, :time_slot_id, :user_id, :name

  json.lead do
    json.name site_visit.lead.name
    json.email site_visit.lead.email
    json.phone site_visit.lead.phone
  end
end
