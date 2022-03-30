json.current_page @booking_details.current_page
json.per_page @booking_details.per_page
json.total_entries @booking_details.total_entries

json.entries @booking_details do |booking_detail|
  json.extract! booking_detail, :_id, :account_manager_id, :agreement_date, :agreement_price, :all_inclusive_price, :bathrooms, :bedrooms, :booked_on, :booking_project_unit_name, :channel_partner_id, :cp_admin_id, :cp_manager_id, :incentive_generated, :lead_id, :manager_id, :manual_tasks_completed, :name, :primary_user_kyc_id, :project_id, :project_name, :project_tower_id, :project_tower_name, :project_unit_configuration, :project_unit_id, :site_visit_id, :source, :status, :system_tasks_completed, :tentative_agreement_date, :user_id, :user_kyc_ids
  json.ds_name booking_detail.ds_name
end
