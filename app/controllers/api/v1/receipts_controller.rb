class Api::V1::ReceiptsController < ApisController
  before_action :reference_ids_present?
  before_action :set_lead, only: :create
  before_action :set_receipt_and_lead, only: :update
  before_action :add_third_party_reference_params, :modify_params

  def create
    unless Receipt.reference_resource_exists?(@crm.id, params[:receipt][:reference_id])
      @receipt = Receipt.new(receipt_create_params)
      @receipt.creator_id = @crm.user_id
      if @receipt.save
        response = generate_response
        response[:message] = 'Receipt successfully created'
        render json: response, status: :created
      else
        render json: {errors: @receipt.errors.full_messages.uniq}, status: :unprocessable_entity
      end
    else
      render json: {errors: ["Receipt with reference_id '#{params[:receipt][:reference_id]}' already exists"]}, status: :unprocessable_entity
    end
  end

  def update
    unless Receipt.reference_resource_exists?(@crm.id, params[:receipt][:reference_id])
      @receipt.assign_attributes(receipt_update_params)
      if @receipt.save
        response = generate_response
        response[:message] = 'Receipt successfully updated'
        render json: response, status: :created
      else
        render json: {errors: @receipt.errors.full_messages.uniq}, status: :unprocessable_entity
      end
    else
      render json: {errors: ["Receipt with reference_id '#{params[:receipt][:reference_id]}' already exists"]}, status: :unprocessable_entity
    end
  end

  def reference_ids_present?
    if params[:action] == 'create'
      render json: { errors: ['reference_id is required to create Receipt'] }, status: :bad_request and return unless params.dig(:receipt, :reference_id).present?
      render json: { errors: ['Lead_id is required to create Receipt'] }, status: :bad_request and return unless params.dig(:receipt, :lead_id).present?
    end
    render json: { errors: ['user kyc reference id is required to create user KYC for receipt'] }, status: :bad_request and return if params.dig(:receipt, :user_kyc_attributes).present? && !params.dig(:receipt, :user_kyc_attributes, :reference_id).present?
  end

  def set_lead
    @lead = Lead.where("third_party_references.crm_id": @crm.id, "third_party_references.reference_id": params[:receipt][:lead_id]).first
    render json: { errors: ["Lead with reference_id '#{ params[:receipt][:lead_id] }' not found"] }, status: :not_found and return unless @lead
  end

  def set_receipt_and_lead
    @receipt = Receipt.where("third_party_references.crm_id": @crm.id, "third_party_references.reference_id": params[:id]).first
    render json: { errors: ["Receipt with reference_id '#{ params[:id] }' not found"] }, status: :not_found and return unless @receipt
    render json: { errors: ["Receipt with reference_id '#{ params[:id] }' is already in success"] }, status: :not_found and return if @receipt.success?
    @lead = @receipt.lead
  end

  def add_third_party_reference_params
    if receipt_reference_id = params.dig(:receipt, :reference_id).presence
      # add third party references
      tpr_attrs = {
        crm_id: @crm.id.to_s,
        reference_id: receipt_reference_id
      }
      if @receipt
        tpr = @receipt.third_party_references.where(reference_id: params[:id], crm_id: @crm.id).first
        tpr_attrs[:id] = tpr.id.to_s if tpr
      end
      params[:receipt][:third_party_references_attributes] = [ tpr_attrs ]
    end
  end

  def modify_receipts_params
    errors = []
    begin
      params[:receipt][:issued_date] = Date.strptime(params[:receipt][:issued_date], "%d/%m/%Y") if params[:receipt][:issued_date].present?
    rescue ArgumentError
      errors << "Issued date format is invalid for receipt. Correct date format is - dd/mm/yyyy"
    end
    begin
      params[:receipt][:processed_on] = Date.strptime(params[:receipt][:processed_on], "%d/%m/%Y") if params[:receipt][:processed_on].present?
    rescue ArgumentError
      errors << "Processed on date format is invalid for receipt. Correct date format is - dd/mm/yyyy"
    end

    if params[:receipt][:status].present?
      errors << "Status should be clearance_pending or success" unless %w[clearance_pending success].include?( params[:receipt][:status])
    else
      params[:receipt][:status] = "clearance_pending"
    end
    errors << "Payment identifier can't be blank" if params[:action] == "create" && !params[:receipt][:payment_identifier].present?
    params[:receipt][:lead_id] = @lead.id.to_s
    params[:receipt][:user_id] = @lead.user.id.to_s
    params[:receipt][:project_id] = @lead.project.id.to_s
    if errors.present?
      "Receipt errors - " + errors.to_sentence
    else
      nil
    end
  end

  def modify_user_kyc_params
    errors = []
    if params[:receipt][:user_kyc_attributes].present?
      if @receipt.present? && @receipt.user_kyc.present?
        errors << "User KYC is already present on receipt"
        return "User kyc errors - " + errors.to_sentence
      end
      begin
        params[:receipt][:user_kyc_attributes][:dob] = Date.strptime(params[:receipt][:user_kyc_attributes][:dob], "%d/%m/%Y") if params[:receipt][:user_kyc_attributes][:dob].present?
      rescue ArgumentError
        errors << 'DOB date format is invalid. Correct date format is - dd/mm/yyyy'
      end
      begin
        params[:receipt][:user_kyc_attributes][:anniversary] = Date.strptime(params[:receipt][:user_kyc_attributes][:anniversary], "%d/%m/%Y") if params[:receipt][:user_kyc_attributes][:anniversary].present?
      rescue ArgumentError
        errors << 'Anniversay date format is invalid. Correct date format is - dd/mm/yyyy'
      end
      errors << "NRI should be a boolean value - true or false" if params[:receipt][:user_kyc_attributes][:nri] && !params[:receipt][:user_kyc_attributes][:nri].is_a?(Boolean)
      errors << "POA should be a boolean value - true or false" if params[:receipt][:user_kyc_attributes][:poa] && !params[:receipt][:user_kyc_attributes][:poa].is_a?(Boolean)
      errors << "Is Company should be a boolean value - true or false" if params[:receipt][:user_kyc_attributes][:is_company] && !params[:receipt][:user_kyc_attributes][:is_company].is_a?(Boolean)
      errors << "Existing customer should be a boolean value - true or false" if params[:receipt][:user_kyc_attributes][:existing_customer] && !params[:receipt][:user_kyc_attributes][:existing_customer].is_a?(Boolean)
      errors << "Number of units should be an integer" if params[:receipt][:user_kyc_attributes][:number_of_units] && !params[:receipt][:user_kyc_attributes][:number_of_units].is_a?(Integer)
      errors << "Budget should be an integer" if params[:receipt][:user_kyc_attributes][:budget] && !params[:receipt][:user_kyc_attributes][:budget].is_a?(Integer)
      params[:receipt][:user_kyc_attributes][:lead_id] = @lead.id.to_s
      if kyc_reference_id = params.dig(:receipt, :user_kyc_attributes, :reference_id).presence
      # add third party references
        tpr_attrs = {
          crm_id: @crm.id.to_s,
          reference_id: kyc_reference_id
        }
        params[:receipt][:user_kyc_attributes][:third_party_references_attributes] = [ tpr_attrs ]
      end
    end
    if errors.present?
      "User kyc errors - " + errors.to_sentence
    else
      nil
    end
  end

  def modify_params
    errors = []
    errors << modify_user_kyc_params
    errors << modify_receipts_params
    render json: { errors: errors.flatten.compact }, status: :unprocessable_entity and return if errors.flatten.compact.present?
  end

  def user_kyc_params
    [:lead_id, :salutation, :first_name, :last_name, :email, :phone, :dob, :pan_number, :aadhaar, :anniversary, :education_qualification, :designation, :customer_company_name, :number_of_units, :budget, :comments, :nri, :oci, :poa, :poa_details, :poa_details_phone_no, :is_company, :gstn, :company_name, :existing_customer, :existing_customer_name, :existing_customer_project,  third_party_references_attributes: [:crm_id, :reference_id], preferred_floors: [], configurations: [], addresses_attributes: [:id, :one_line_address, :address1, :address2, :city, :state, :country, :country_code, :zip, :primary, :address_type]]
  end

  def receipt_create_params
    params.require(:receipt).permit(:project_id, :lead_id, :user_id, :payment_mode, :issued_date, :issuing_bank, :issuing_bank_branch, :payment_identifier, :tracking_id, :total_amount, :status_message, :payment_gateway, :processed_on, :comments, :payment_type, third_party_references_attributes: [:crm_id, :reference_id], user_kyc_attributes: user_kyc_params)
  end

  def receipt_update_params
    params.require(:receipt).permit( :issued_date, :issuing_bank, :issuing_bank_branch, :payment_identifier, :tracking_id, :total_amount, :status_message, :processed_on, :comments, third_party_references_attributes: [:id, :reference_id], user_kyc_attributes: user_kyc_params)
  end

  def generate_response
    response = {receipt_id: @receipt.id.to_s}
    receipts_statuses = %w[clearance_pending success]
    receipts_statuses.each do |event|
      @receipt.assign_attributes(event: event)
      unless @receipt.save
        errors = @receipt.state_machine_errors + @receipt.errors
        @receipt.assign_attributes(state_machine_errors: errors)
        @receipt.save
      end
      break if params[:receipt][:status] == event
    end
    response[:status_change_errors] = @receipt.state_machine_errors if @receipt.state_machine_errors.present?
    response[:user_kyc_id] = @receipt.user_kyc.id.to_s if params.dig(:receipt, :user_kyc_attributes).present? 
    response
  end
end