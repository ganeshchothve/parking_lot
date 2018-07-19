require 'spreadsheet'
class UserContactBookExportWorker
  include Sidekiq::Worker

  def perform emails
    file = Spreadsheet::Workbook.new
    sheet = file.create_worksheet(name: "Customer Contact Book Report")
    sheet.insert_row(0, UserContactBookExportWorker.get_column_names)
    BookingDetail.where(status: {"$ne" => "cancelled"}).each_with_index do |booking_detail, index|
      sheet.insert_row(index+1, UserContactBookExportWorker.get_user_request_row(booking_detail.primary_user_kyc, booking_detail))
      booking_detail.user_kycs.each do |co_applicant_kyc|
        sheet.insert_row(index+1, UserContactBookExportWorker.get_user_request_row(co_applicant_kyc,booking_detail))
      end
    end
    file_name = "Customer-Contact-Book-#{SecureRandom.hex}.xls"
    file.write("#{Rails.root}/#{file_name}")
    ExportMailer.notify(file_name, emails, "Customer Contact Book Report").deliver
  end

  def self.get_column_names
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
      "Loan Required",
      "Bank Name",
      "Is an Existing Customer",
      "Existing Customer Name",
      "Existing Customer Project Name",
      "Comments",
      "User ID (Used for VLOOKUP)",
      "Created by",
      "Property Name",
      "Status",
      "Aggrement Amount"
      ]
  end

  def self.get_user_request_row(user_kyc, booking_detail)
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
      user_kyc.loan_required? ? "Yes" : "No",
      user_kyc.bank_name,
      user_kyc.existing_customer? ? "Yes" : "No",
      user_kyc.existing_customer_name,
      user_kyc.existing_customer_project,
      user_kyc.comments,
      user_kyc.user_id.to_s,
      user_kyc.creator.name,
      booking_detail.project_unit.name,
      booking_detail.project_unit.status.humanize,
      booking_detail.project_unit.agreement_price
    ]
  end
end
