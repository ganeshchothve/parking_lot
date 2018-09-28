require 'spreadsheet'
class UserExportWorker
  include Sidekiq::Worker
  extend ApplicationHelper

  def perform user_id, filters={}
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
    file.write("#{Rails.root}/#{file_name}")

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
      user_kyc.user_id.to_s,
      user_kyc.creator.name
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
      "Referred by Partner",
      "RERA ID",
      "Last Sign In At",
      "Confirmed",
      "Confirmed At"
    ]
  end

  def self.get_user_row user, current_user
    [
      user.id.to_s,
      user.name,
      user.email,
      user.phone,
      user.buyer? ? user.lead_id : "",
      User.available_roles(current_client).select{|x| x[:id] == user.role}.first[:text],
      user.manager_id.present? ? User.find(user.manager_id).name : "",
      user.role?("channel_partner") ? user.rera_id : "",
      user.last_sign_in_at.present? ? I18n.l(user.last_sign_in_at.in_time_zone(current_user.time_zone)) : "",
      user.confirmed? ? "Yes" : "No",
      user.confirmed_at.present? ? I18n.l(user.confirmed_at.in_time_zone(current_user.time_zone)) : ""
    ]
  end
end
