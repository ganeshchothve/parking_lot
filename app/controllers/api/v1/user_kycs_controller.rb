class Api::V1::UserKycsController < ApisController
  before_action :reference_ids_present?, only: :create
  before_action :set_lead
  before_action :set_user_kyc, only: :update
  before_action :add_third_party_reference_params, :modify_params

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
    unless @lead.user_kycs.reference_resource_exists?(@crm.id, params[:user_kyc][:reference_id])
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
    unless @lead.user_kycs.reference_resource_exists?(@crm.id, params[:user_kyc][:reference_id])
      @user_kyc.assign_attributes(user_kyc_params)
      if @user_kyc.save
        render json: {user_kyc_id: @user_kyc.id, message: 'User KYC successfully updated.'}, status: :created
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
    render json: { errors: ['user kyc reference_id is required'] }, status: :bad_request and return unless params.dig(:user_kyc, :reference_id)
  end

  def set_lead
    unless lead_reference_id = params.dig(:user_kyc, :lead_id).presence
      render json: { errors: ['lead_id is required to create Kyc'] }, status: :bad_request
    else
      @lead = Lead.where("third_party_references.crm_id": @crm.id, "third_party_references.reference_id": lead_reference_id).first
      render json: { errors: ["Lead with reference id #{lead_reference_id} not found"] }, status: :not_found and return unless @lead
    end
  end

  def set_user_kyc
    @user_kyc = UserKyc.where("third_party_references.crm_id": @crm.id, "third_party_references.reference_id": params[:id]).first
    render json: { errors: ["User Kyc with reference_id '#{params[:id]}' not found"] }, status: :not_found unless @user_kyc
  end

  def add_third_party_reference_params
    if user_kyc_reference_id = params.dig(:user_kyc, :reference_id).presence
      # add third party references
      tpr_attrs = {
        crm_id: @crm.id.to_s,
        reference_id: user_kyc_reference_id
      }
      if @user_kyc
        tpr = @user_kyc.third_party_references.where(reference_id: params[:id], crm_id: @crm.id).first
        tpr_attrs[:id] = tpr.id.to_s if tpr
      end
      params[:user_kyc][:third_party_references_attributes] = [ tpr_attrs ]
    end
  end

  def modify_params
    errors = []
    begin
      params[:user_kyc][:dob] = Date.strptime(params[:user_kyc][:dob], "%d/%m/%Y") if params[:user_kyc][:dob].present?
    rescue ArgumentError
      errors << 'DOB date format is invalid. Correct date format is - dd/mm/yyyy'
    end
    begin
      params[:user_kyc][:anniversary] = Date.strptime(params[:user_kyc][:anniversary], "%d/%m/%Y") if params[:user_kyc][:anniversary].present?
    rescue ArgumentError
      errors << 'Anniversay date format is invalid. Correct date format is - dd/mm/yyyy'
    end
    errors << "NRI should be a boolean value - true or false" if !params[:user_kyc][:nri].is_a?(Boolean)
    errors << "POA should be a boolean value - true or false" if !params[:user_kyc][:poa].is_a?(Boolean)
    errors << "Is Company should be a boolean value - true or false" if !params[:user_kyc][:is_company].is_a?(Boolean)
    errors << "Existing customer should be a boolean value - true or false" if !params[:user_kyc][:existing_customer].is_a?(Boolean)
    errors << "Number of units should be an integer" if !params[:user_kyc][:number_of_units].is_a?(Integer)
    errors << "Budget should be an integer" if !params[:user_kyc][:budget].is_a?(Integer)
    if @user_kyc
      params[:user_kyc][:addresses_attributes].each_with_index do |addr_attrs, i|
        addr = @user_kyc.addresses.where(address_type: addr_attrs[:address_type]).first
        params[:user_kyc][:addresses_attributes][i][:id] = addr.id.to_s if addr.present?
      end
    end
    render json: { errors: errors } if errors.present?
  end

end