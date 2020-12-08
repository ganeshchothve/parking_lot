class Api::V1::UserKycsController < ApisController
  include Api::UserKycsConcern
  before_action :reference_ids_present?, :set_lead, only: :create
  before_action :set_user_kyc_and_lead, only: :update
  before_action :check_params, :modify_params

  #
  # The create action always creates a new user kyc alongwith storing reference ids of third party CRM system.
  #
  # POST  /api/v1/user_kycs
  #
  #   {
  #   "user_kyc":
  #   {
  #     "salutation": "Mr.",
  #     "first_name": "Aakruti",
  #     "last_name": "Shitut",
  #     "email": "aaabcd@gmail.com",
  #     "phone": "+914999993313",
  #     "pan_number": "AAABA9961A",
  #     "aadhaar": "123412141234",
  #     "dob": "12/08/1980",
  #     "configurations": ["1", "1.5"],
  #     "preferred_floors": ["1"],
  #     "budget": 123456,
  #     "anniversary": "11/11/1995",
  #     "education_qualification": "ABC",
  #     "designation": "ABC",
  #     "customer_company_name": "ABC",
  #     "number_of_units": 1,
  #     "comments": "ABC",
  #     "nri": true,
  #     "oci": "ABC",
  #     "poa": true,
  #     "poa_details": "ABC",
  #     "poa_details_phone_no": "ABC",
  #     "is_company": true,
  #     "gstn": "ABC",
  #     "company_name": "ABC",
  #     "existing_customer": true,
  #     "existing_customer_name": "ABC",
  #     "existing_customer_project": "ABC",
  #     "addresses_attributes": [{"one_line_address": "ABC"}, {"one_line_address": "ABCDDD", "address_type": "AAA"}]
  #     "reference_id": <user_kyc_reference_id>,
  #     "lead_id": <lead_reference_id>,
  #   }
  # }
  def create
    unless @lead.user_kycs.reference_resource_exists?(@crm.id, params[:user_kyc][:reference_id].to_s)
      @user_kyc = @lead.user_kycs.build(user_kyc_params)
      if @user_kyc.save
        render json: {user_kyc_id: @user_kyc.id, lead_id: @lead.id, message: 'User KYC successfully created.'}, status: :created
      else
        render json: {errors: @user_kyc.errors.full_messages.uniq}, status: :unprocessable_entity
      end
    else
      render json: {errors: ["User KYC with reference_id '#{params[:user_kyc][:reference_id]}' already exists"]}, status: :unprocessable_entity
    end
  end

  #
  # The update action will update the details of an existing user_kyc using the reference_id for identification.
  #
  # PATCH     /api/v1/user_kycs/:reference_id
  #
  #   {
  #   "user_kyc":
  #   {
  #     "salutation": "Mr.",
  #     "first_name": "Aakruti",
  #     "last_name": "Shitut",
  #     "email": "aaabcd@gmail.com",
  #     "phone": "+914999993313",
  #     "pan_number": "AAABA9961A",
  #     "aadhaar": "123412141234",
  #     "dob": "12/08/1980",
  #     "configurations": ["1", "1.5"],
  #     "preferred_floors": ["1"],
  #     "budget": 123456,
  #     "anniversary": "11/11/1995",
  #     "education_qualification": "ABC",
  #     "designation": "ABC",
  #     "customer_company_name": "ABC",
  #     "number_of_units": 1,
  #     "comments": "ABC",
  #     "nri": true,
  #     "oci": "ABC",
  #     "poa": true,
  #     "poa_details": "ABC",
  #     "poa_details_phone_no": "ABC",
  #     "is_company": true,
  #     "gstn": "ABC",
  #     "company_name": "ABC",
  #     "existing_customer": true,
  #     "existing_customer_name": "ABC",
  #     "existing_customer_project": "ABC",
  #     "addresses_attributes": [{"one_line_address": "ABC", "address_type": "permanent"}, {"one_line_address": "ABCDDDs555s", "address_type": "AAA"}]
  #     "reference_id": <new - user_kyc_reference_id>,
  #     "lead_id": <lead_reference_id>,
  #   }
  # }
  def update
    unless @lead.user_kycs.reference_resource_exists?(@crm.id, params[:user_kyc][:reference_id].to_s)
      @user_kyc.assign_attributes(user_kyc_params)
      if @user_kyc.save
        render json: {user_kyc_id: @user_kyc.id, message: 'User KYC successfully updated.'}, status: :ok
      else
        render json: {errors: @user_kyc.errors.full_messages.uniq}, status: :unprocessable_entity
      end
    else
      render json: {errors: ["User KYC with reference_id '#{params[:user_kyc][:reference_id]}' already exists"]}, status: :unprocessable_entity
    end
  end

  private

  def user_kyc_params
    params.require(:user_kyc).permit(:salutation, :first_name, :last_name, :email, :phone, :dob, :pan_number, :aadhaar, :anniversary, :education_qualification, :designation, :customer_company_name, :number_of_units, :budget, :comments, :nri, :oci, :poa, :poa_details, :poa_details_phone_no, :is_company, :gstn, :company_name, :existing_customer, :existing_customer_name, :existing_customer_project,  third_party_references_attributes: [:id, :crm_id, :reference_id], preferred_floors: [], configurations: [], addresses_attributes: [:id, :one_line_address, :address1, :address2, :city, :state, :country, :country_code, :zip, :primary, :address_type])
  end

  # Checks if the required reference_id's are present. reference_id is the third party CRM resource id.
  def reference_ids_present?
    render json: { errors: ['user kyc reference_id is required'] }, status: :bad_request and return unless params.dig(:user_kyc, :reference_id).present?
  end

  def set_lead
    unless lead_reference_id = params.dig(:user_kyc, :lead_id).presence
      render json: { errors: ['lead_id is required to create Kyc'] }, status: :bad_request
    else
      @lead = Lead.where("third_party_references.crm_id": @crm.id, "third_party_references.reference_id": lead_reference_id).first
      render json: { errors: ["Lead with reference id #{lead_reference_id} not found"] }, status: :not_found and return unless @lead
    end
  end

  def set_user_kyc_and_lead
    @user_kyc = UserKyc.where("third_party_references.crm_id": @crm.id, "third_party_references.reference_id": params[:id]).first
    render json: { errors: ["User Kyc with reference_id '#{params[:id]}' not found"] }, status: :not_found and return unless @user_kyc
    @lead = @user_kyc.lead
  end

  def check_params
    errors = []
    errors << check_any_user_kyc_params(params.dig(:user_kyc))
    render json: { errors: errors.compact }, status: :unprocessable_entity and return if errors.try(:compact).present?
  end

  def modify_params
    params[:user_kyc] = modify_any_user_kyc_params(params.dig(:user_kyc))
  end

end