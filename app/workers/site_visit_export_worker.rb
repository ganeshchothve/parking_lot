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
      "Name",
      "Email Id",
      "Phone",
      "Project Name",
      "Scheduled on",
      "Status",
      "Conducted on",
      "Approval Status",
      "Partner / Manager / Added by",
    ] + Crm::Base.all.map{|crm| crm.name + " SiteVisit ID"  }

    sv_columns.flatten
  end

  def self.get_site_visit_row(sv, user)
    sv_row = [
      sv.lead&.name,
      sv.lead&.masked_email(user),
      sv.lead&.masked_phone(user),
      sv.project_name,
      sv.scheduled_on.try(:strftime, '%d/%m/%Y %I:%M %p'),
      sv.status&.titleize,
      sv.conducted_on.try(:strftime, '%d/%m/%Y %I:%M %p'),
      sv.approval_status&.titleize,
      sv.manager.try(:name),
    ] + Crm::Base.all.map{|crm| sv.third_party_references.where(crm_id: crm.id).first.try(:reference_id) }

    sv_row.flatten
  end
end
