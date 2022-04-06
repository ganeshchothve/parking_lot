json.current_page @booking_details.current_page
json.per_page @booking_details.per_page
json.total_entries @booking_details.total_entries

json.entries @booking_details do |booking_detail|
  json.extract! booking_detail, :_id, :account_manager_id, :agreement_price, :all_inclusive_price, :bathrooms, :bedrooms, :booking_project_unit_name, :channel_partner_id, :cp_admin_id, :cp_manager_id, :incentive_generated, :lead_id, :manager_id, :manual_tasks_completed, :name, :primary_user_kyc_id, :project_id, :project_tower_id, :project_tower_name, :project_unit_configuration, :project_unit_id, :site_visit_id, :source, :system_tasks_completed, :user_id, :user_kyc_ids

  json.status BookingDetail.human_attribute_name("status.#{booking_detail.status}")
  json.project_name booking_detail.project&.name
  json.agreement_date (booking_detail.agreement_date.present? ? l(booking_detail.agreement_date) : nil)
  json.tentative_agreement_date (booking_detail.tentative_agreement_date.present? ? l(booking_detail.tentative_agreement_date) : nil)
  json.booked_on (booking_detail.booked_on.present? ? l(booking_detail.booked_on) : nil)
  json.ds_name booking_detail.ds_name
  json.lead_name booking_detail.lead&.name
end
