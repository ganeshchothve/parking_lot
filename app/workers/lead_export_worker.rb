require 'spreadsheet'
class LeadExportWorker
  include Sidekiq::Worker

  def perform user_id, filters=nil
    if filters.present? && filters.is_a?(String)
      filters =  JSON.parse(filters)
    end
    user = User.find(user_id)
    file = Spreadsheet::Workbook.new
    sheet = file.create_worksheet(name: "Leads")
    sheet.insert_row(0, LeadExportWorker.get_column_names)
    lead_column_size = LeadExportWorker.get_column_names.size rescue 0
    lead_column_size.times { |x| sheet.row(0).set_format(x, title_format) } #making headers bold
    Lead.where(Lead.user_based_scope(user)).build_criteria({fltrs: filters}.with_indifferent_access).each_with_index do |lead, index|
      sheet.insert_row(index+1, LeadExportWorker.get_lead_row(lead))
    end
    file_name = "lead-#{SecureRandom.hex}.xls"
    file.write("#{Rails.root}/exports/#{file_name}")
    ExportMailer.notify(file_name, user.email, "Leads").deliver
  end

  #code for make excel headers bold
  def title_format
    Spreadsheet::Format.new(
      weight: :bold,
    )
  end

  def self.get_column_names
    lead_columns = [
      "Lead Id",
      "Name",
      "Email Id",
      "Phone",
      "Stage",
      "Project Name",
      "Site visit Date",
      "Number of Re-Visit",
      "Last Revisit date",
      "Queue No.",
      I18n.t('mongoid.attributes.user.manager_id'),
      "Booking Amount Paid",
      "9.90% Received",
      "Registration Done",
      "Registered/Opportunity Created Date"
    ] + Crm::Base.all.map{|crm| crm.name + " Opportunity ID"  }

    lead_columns.append(Crm::Base.all.map{|crm| crm.name + " CP record ID"  }.try(:first))
    lead_columns.flatten
  end



  def self.get_lead_row(lead)
    lead_row = [
      lead.id.to_s,
      lead.name,
      lead.email,
      lead.phone,
      lead.stage,
      lead.project_name,
      lead.sitevisit_date.try(:strftime, '%d/%m/%Y'),
      lead.revisit_count.to_i,
      lead.last_revisit_date.try(:strftime, '%d/%m/%Y'),
      lead.queue_number,
      lead.manager.try(:name),
      (lead.booking_details.map(&:total_amount_paid).sum rescue 0.0),
      (lead.is_booking_price_paid? ? "Yes" : "No"),
      (lead.is_registration_done? ? "Yes" : "No"),
      (lead.registered_at.try(:strftime, '%d/%m/%Y') || lead.created_at.try(:strftime, '%d/%m/%Y'))
    ] + Crm::Base.all.map{|crm| lead.third_party_references.where(crm_id: crm.id).first.try(:reference_id) }

    lead_row.append((Crm::Base.all.map{|crm| lead.manager.third_party_references.where(crm_id: crm.id).first.try(:reference_id) }.first rescue ""))
    lead_row.flatten
  end
end

#crm id name/ ref id
#stuck in column headers
