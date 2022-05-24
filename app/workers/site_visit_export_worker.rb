require 'spreadsheet'
class SiteVisitExportWorker
  include Sidekiq::Worker

  def perform user_id, filters=nil
    if filters.present? && filters.is_a?(String)
      filters =  JSON.parse(filters)
    end
    user = User.find(user_id)
    file = Spreadsheet::Workbook.new
    sheet = file.create_worksheet(name: SiteVisit.model_name.human(count: 2))
    sheet.insert_row(0, SiteVisitExportWorker.get_column_names)
    site_visits_column_size = SiteVisitExportWorker.get_column_names.size rescue 0
    site_visits_column_size.times { |x| sheet.row(0).set_format(x, title_format) } #making headers bold
    SiteVisit.where(SiteVisit.user_based_scope(user)).build_criteria({fltrs: filters}.with_indifferent_access).each_with_index do |sv, index|
      sheet.insert_row(index+1, SiteVisitExportWorker.get_site_visit_row(sv, user))
    end
    file_name = "#{SiteVisit.model_name.human(count: 2)}-#{SecureRandom.hex}.xls"
    file.write("#{Rails.root}/exports/#{file_name}")
    ExportMailer.notify(file_name, user.email, SiteVisit.model_name.human(count: 2)).deliver
  end

  #code for make excel headers bold
  def title_format
    Spreadsheet::Format.new(
      weight: :bold,
    )
  end

  def self.get_column_names
    sv_columns = [
      "Id",
      "User ID(lead)",
      "Name",
      "Email Id",
      "Phone",
      "Project Name",
      "Created at",
      "Scheduled on",
      "Status",
      "Conducted on",
      "Approval Status",
      "Channel Partner Manager",
      I18n.t('mongoid.attributes.site_visit.manager_id'),
      "Partner ID (Used for VLOOKUP)",
      "Partner Phone",
      "Partner UPI Address",
      "Partner Role",
    ] + Crm::Base.all.map{|crm| crm.name + " SiteVisit ID"  }

    sv_columns.flatten
  end

  def self.get_site_visit_row(sv, user)
    sv_row = [
      sv.id.to_s,
      sv.lead&.id.to_s,
      sv.lead&.name,
      sv.lead&.masked_email(user),
      sv.lead&.masked_phone(user),
      sv.project_name,
      I18n.l(sv.created_at),
      I18n.l(sv.scheduled_on),
      sv.status&.titleize,
      sv.conducted_on.present? ? I18n.l(sv.conducted_on) : "",
      sv.approval_status&.titleize,
      sv.cp_manager&.name,
      sv.manager&.name,
      sv.manager_id.to_s,
      sv.manager&.phone,
      sv.manager&.fund_accounts&.first.try(:address),
      sv.manager&.role,
    ] + Crm::Base.all.map{|crm| sv.third_party_references.where(crm_id: crm.id).first.try(:reference_id) }

    sv_row.flatten
  end
end
