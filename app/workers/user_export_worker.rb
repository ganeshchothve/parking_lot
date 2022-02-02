require 'spreadsheet'
class UserExportWorker
  include Sidekiq::Worker
  extend ApplicationHelper

  def perform user_id, filters=nil
    if filters.present? && filters.is_a?(String)
      filters =  JSON.parse(filters)
    end
    current_user = User.find(user_id)
    file = Spreadsheet::Workbook.new
    sheet = file.create_worksheet(name: "Users")
    sheet.insert_row(0, UserExportWorker.get_column_names)
    users = User.build_criteria({fltrs: filters}.with_indifferent_access)
    users = users.where(User.user_based_scope(current_user))
    users.each_with_index do |user, index|
      sheet.insert_row(index+1, UserExportWorker.get_user_row(user, current_user))
    end
    sheet = file.create_worksheet(name: "User KYCs")
    sheet.insert_row(0, UserExportWorker.get_kyc_column_names)
    UserKyc.where(UserKyc.user_based_scope(current_user)).all.each_with_index do |user_kyc, index|
      sheet.insert_row(index+1, UserExportWorker.get_user_kyc_row(user_kyc, current_user))
    end
    file_name = "user-#{SecureRandom.hex}.xls"
    file.write("#{Rails.root}/exports/#{file_name}")

    ExportMailer.notify(file_name, current_user.email, "Users & User KYCs").deliver
  end

  def self.get_kyc_column_names
    [
      "Name",
      "Email",
      "Phone",
      "DOB",
      "PAN Number",
      "Aadhaar",
      "GSTN",
      "Is a Company",
      "Anniversary",
      "NRI",
      "POA",
      "POA Details",
      "Company Name",
      "Is an Existing Customer",
      "Existing Customer Name",
      "Existing Customer Project Name",
      "Comments",
      "User ID (Used for VLOOKUP)",
      "Created by"
    ]
  end

  def self.get_user_kyc_row user_kyc, current_user
    [
      user_kyc.name,
      user_kyc.email,
      user_kyc.phone,
      user_kyc.dob,
      user_kyc.pan_number,
      user_kyc.aadhaar,
      user_kyc.gstn,
      user_kyc.is_company? ? "Yes" : "No",
      user_kyc.anniversary,
      user_kyc.nri? ? "Yes" : "No",
      user_kyc.poa? ? "Yes" : "No",
      user_kyc.poa_details,
      user_kyc.company_name,
      user_kyc.existing_customer? ? "Yes" : "No",
      user_kyc.existing_customer_name,
      user_kyc.existing_customer_project,
      user_kyc.comments,
      user_kyc.user_id&.to_s,
      user_kyc.creator&.name
    ]
  end

  def self.get_column_names
    [
      "ID (Used for VLOOKUP)",
      "Name",
      "Email",
      "Phone",
      "Sell.Do Lead ID",
      "Role",
      "Manager Name",
      "Regions",
      "RERA ID",
      "UPI Address",
      "Last Sign In At",
      "Confirmed",
      "Confirmed At",
      "Referral Code",
      "Referred By",
      "Referred By ID (Used for VLOOKUP)",
      "Sign-in-count",
      "Company Name",
      "Walkin Count"
    ]
  end

  def self.get_user_row user, current_user
    [
      user.id.to_s,
      user.name,
      user.email,
      user.phone,
      user.buyer? ? user.lead_id : "",
      User.human_attribute_name("role.#{user.role}"),
      user.manager_name || "",
      user.channel_partner&.regions&.to_sentence,
      user.role.in?(%w(cp_owner channel_partner)) ? user.rera_id : "",
      user.role.in?(%w(cp_owner channel_partner)) ? user.fund_accounts.first.try(:address) : "",
      user.last_sign_in_at.present? ? I18n.l(user.last_sign_in_at) : "",
      user.confirmed? ? "Yes" : "No",
      user.confirmed_at.present? ? I18n.l(user.confirmed_at) : "",
      user.referral_code,
      user.referred_by.try(:name),
      user.referred_by_id.to_s,
      user.sign_in_count,
      user.role.in?(%w(cp_owner channel_partner)) ? user.channel_partner.try(:company_name) : "",
      site_visit_count(user)
    ]
  end

  def self.site_visit_count(user)
    case user.role
    when 'cp_owner', 'channel_partner'
      SiteVisit.where(manager_id: user.id).count
    when 'cp'
      SiteVisit.where(cp_manager_id: user.id).count
    when 'cp_admin'
      SiteVisit.where(cp_admin_id: user.id).count
    else
      user.site_visits.count
    end
  end
end
