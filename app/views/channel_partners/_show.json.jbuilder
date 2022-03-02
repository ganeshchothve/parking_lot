if channel_partner.present?
  json.(channel_partner, :_id, :aadhaar, :average_quarterly_business, :category, :company_name, :company_owner_name, :company_owner_phone, :company_type, :created_at, :developers_worked_for, :experience, :expertise, :gst_applicable, :gstin_number, :interested_services, :manager_id, :nri, :pan_number, :primary_user_id, :regions, :rera_applicable, :rera_id, :status, :team_size, :website)
  json.status_change_reason channel_partner.try(:status_message)
end
