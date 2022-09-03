class Api::V1::ReceiptsController < ApisController
  include Api::UserKycsConcern
  include Api::ReceiptsConcern
  before_action :reference_ids_present?
  before_action :set_lead, only: :create
  before_action :set_receipt_and_lead, only: :update
  before_action :check_params, :modify_params

  def create
    unless Receipt.reference_resource_exists?(@crm.id, params[:receipt][:reference_id].to_s)
      @receipt = Receipt.new(receipt_create_params)
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
    unless Receipt.reference_resource_exists?(@crm.id, params[:receipt][:reference_id].to_s)
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
    render json: { errors: ["Receipt with reference_id '#{ params[:id] }' is already in success"] }, status: :unprocessable_entity and return if @receipt.success?
    @lead = @receipt.lead
  end

  def check_user_kyc_params
    errors = []
    if kyc_attributes = params.dig(:receipt, :user_kyc_attributes)
      if @receipt.present? && @receipt.user_kyc.present?
        errors << "User KYC is already present on receipt"
        return { "User kyc errors - ": errors.try(:compact) }
      end
      errors << check_any_user_kyc_params(kyc_attributes)
    end
    { "User kycs errors - ": errors.try(:compact) } if errors.try(:compact).present?
  end

  def check_params
    errors = []
    errors << check_user_kyc_params
    errors << check_any_receipt_params(params[:receipt])
    render json: { errors: errors.compact }, status: :unprocessable_entity and return if errors.try(:compact).present?
  end

  def modify_params
    params[:receipt][:user_kyc_attributes] = modify_any_user_kyc_params(params.dig(:receipt, :user_kyc_attributes))
    params[:receipt] = modify_any_receipt_params(params[:receipt])
  end

  def user_kyc_params
    [:lead_id, :salutation, :first_name, :last_name, :email, :phone, :dob, :pan_number, :aadhaar, :anniversary, :education_qualification, :designation, :customer_company_name, :number_of_units, :budget, :comments, :nri, :oci, :poa, :poa_details, :poa_details_phone_no, :is_company, :gstn, :company_name, :existing_customer, :existing_customer_name, :existing_customer_project, :creator_id,  third_party_references_attributes: [:crm_id, :reference_id], preferred_floors: [], configurations: [], addresses_attributes: [:id, :one_line_address, :address1, :address2, :city, :state, :country, :country_code, :zip, :primary, :address_type]]
  end

  def receipt_create_params
    params.require(:receipt).permit(:creator_id, :project_id, :lead_id, :user_id, :payment_mode, :issued_date, :issuing_bank, :issuing_bank_branch, :payment_identifier, :tracking_id, :total_amount, :status_message, :payment_gateway, :processed_on, :comments, :payment_type, third_party_references_attributes: [:crm_id, :reference_id], user_kyc_attributes: user_kyc_params)
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
        errors = @receipt.state_machine_errors + @receipt.errors.to_a
        @receipt.set(state_machine_errors: errors)
      end
      break if params[:receipt][:status] == event
    end
    response[:status_change_errors] = @receipt.state_machine_errors if @receipt.state_machine_errors.present?
    response[:user_kyc_id] = @receipt.user_kyc.id.to_s if params.dig(:receipt, :user_kyc_attributes).present? 
    response
  end
end
