require 'spreadsheet'
class UserKycExportWorker
  include Sidekiq::Worker

  def perform emails
    file = Spreadsheet::Workbook.new
    sheet = file.create_worksheet(name: "Applicants")
    sheet.insert_row(0, get_column_names)
    index = 0
    ProjectUnit.in(status:["blocked","booked_tentative","booked_confirmed"]).each do |project_unit|
      sheet.insert_row(index+=1, get_user_kyc_row(project_unit.primary_user_kyc, project_unit, true))
      project_unit.user_kycs.each{|user_kyc| sheet.insert_row(index+=1, get_user_kyc_row(user_kyc, project_unit, false))}
    end
    
    file_name = "applicants-#{SecureRandom.hex}.xls"
    file.write("#{Rails.root}/#{file_name}")
    ExportMailer.notify(file_name, "kiran@amuratech.com", "Applicants").deliver
  end

  def self.get_column_names
    [
      "Salutation", 
      "First Name", 
      "Last Name", 
      "Email", 
      "Phone", 
      "Dob", 
      "Pan Number", 
      "Street", 
      "House Number", 
      "City", 
      "Postal Code", 
      "State", 
      "Country", 
      "Correspondence Street", 
      "Correspondence House Number", 
      "Correspondence City", 
      "Correspondence Postal Code", 
      "Correspondence State", 
      "Correspondence Country", 
      "Son Daughter Of", 
      "Education Qualification", 
      "Designation", 
      "Customer Company Name", 
      "Poa Details Phone No", 
      "Aadhaar", 
      "Oci", 
      "Gstn", 
      "Is Company", 
      "Anniversary", 
      "Nri", 
      "Poa", 
      "Poa Details", 
      "Company Name", 
      "Loan Required", 
      "Bank Name", 
      "Existing Customer", 
      "Existing Customer Name", 
      "Existing Customer Project", 
      "Comments", 
      "User ID (Used for VLOOKUP)",
      "Client Name",
      "Unit Name",
      "Unit ID (Used for VLOOKUP)",
      "Primary Applicant?",
      "Unit Status",
      "Creator", 
      "Created At", 
      "Updated At"
    ] 
  end

  def self.get_user_kyc_row(user_kyc, project_unit, is_primary)
    [
     user_kyc.salutation,
     user_kyc.first_name,
     user_kyc.last_name,
     user_kyc.email,
     user_kyc.phone,
     user_kyc.dob,
     user_kyc.pan_number,
     user_kyc.street,
     user_kyc.house_number,
     user_kyc.city,
     user_kyc.postal_code,
     user_kyc.state,
     user_kyc.country,
     user_kyc.correspondence_street,
     user_kyc.correspondence_house_number,
     user_kyc.correspondence_city,
     user_kyc.correspondence_postal_code,
     user_kyc.correspondence_state,
     user_kyc.correspondence_country,
     user_kyc.son_daughter_of,
     user_kyc.education_qualification,
     user_kyc.designation,
     user_kyc.customer_company_name,
     user_kyc.poa_details_phone_no,
     user_kyc.aadhaar,
     user_kyc.oci,
     user_kyc.gstn,
     user_kyc.is_company,
     user_kyc.anniversary,
     user_kyc.nri,
     user_kyc.poa,
     user_kyc.poa_details,
     user_kyc.company_name,
     user_kyc.loan_required,
     user_kyc.bank_name,
     user_kyc.existing_customer,
     user_kyc.existing_customer_name,
     user_kyc.existing_customer_project,
     user_kyc.comments,
     user_kyc.user_id.to_s,
     user_kyc.user.name,
     project_unit.name,
     project_unit.id.to_s,
     is_primary,
     project_unit.status,
     user_kyc.creator_id.to_s,
     user_kyc.created_at,
     user_kyc.updated_at
   ]
  end
end
