class UserKycPolicy < ApplicationPolicy
  # def index?  def new?  def edit?  def create?  def update? from ApplicationPolicy

  def asset_create?
    create?
  end

  def permitted_attributes(_params = {})
    attributes = [:salutation, :first_name, :last_name, :email, :phone, :dob, :pan_number, :aadhaar, :oci, :gstn, :anniversary, :nri, :poa, :customer_company_name, :existing_customer, :comments, :existing_customer_name, :existing_customer_project, :poa_details, :is_company, :education_qualification, :designation, :company_name, :poa_details_phone_no, :number_of_units, :min_budget, :max_budget, correspondence_address_attributes: AddressPolicy.new(user, Address.new).permitted_attributes, permanent_address_attributes: AddressPolicy.new(user, Address.new).permitted_attributes, bank_detail_attributes: BankDetailPolicy.new(user, BankDetail.new).permitted_attributes, configurations: [], preferred_floors: [], project_unit_ids: []]
    attributes
  end
end
