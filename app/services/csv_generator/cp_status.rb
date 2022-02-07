module CsvGenerator::CpStatus

  def  self.cp_status_csv(cp_managers_hash, channel_partners_manager_status_count, channel_partners_status_count)
    attributes = cp_status_csv_headers
    csv_str = CSV.generate(headers: true) do |csv|
      csv << attributes
      cp_managers_hash.each do |cp_id, cp_name|
        csv << [
          cp_name,
          (channel_partners_manager_status_count[cp_id]["inactive"] || 0),
          (channel_partners_manager_status_count[cp_id]["active"] || 0),
          (channel_partners_manager_status_count[cp_id]["pending"] || 0),
          (channel_partners_manager_status_count[cp_id]["rejected"] || 0),
          (channel_partners_manager_status_count[cp_id]["count"] || 0)
        ]
      end
      total_values = ["Total"]
      %w(inactive active pending rejected total).each do |status| 
        total_values << channel_partners_status_count[status] || 0
      end
      csv << total_values
    end
    csv_str
  end

  def self.cp_status_csv_headers
    [
      I18n.t("mongoid.attributes.user/role.cp"),
      I18n.t("dashboard.cp_admin.cp_status.inactive_html"),
      I18n.t("dashboard.cp_admin.cp_status.active_html"),
      I18n.t("dashboard.cp_admin.cp_status.pending_html"),
      I18n.t("dashboard.cp_admin.cp_status.rejected_html"),
      I18n.t("global.total"),
    ]
  end

end
