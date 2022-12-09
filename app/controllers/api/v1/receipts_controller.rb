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
      @receipt.booking_portal_client_id = @current_client.try(:id)
      if @receipt.save
        response = generate_response
        @message = I18n.t("controller.receipts.notice.created")
        response[:message] = @message
        render json: response, status: :created
      else
        @errors = @receipt.errors.full_messages.uniq
        render json: {errors: @errors}, status: :unprocessable_entity
      end
    else
      @errors = ["Receipt with reference_id '#{params[:receipt][:reference_id]}' already exists"]
      render json: {errors: @errors}, status: :unprocessable_entity
    end
  end

  def update
    unless Receipt.reference_resource_exists?(@crm.id, params[:receipt][:reference_id].to_s)
      @receipt.assign_attributes(receipt_update_params)
      if @receipt.save
        response = generate_response
        @message = I18n.t("controller.receipts.notice.updated")
        response[:message] = @message
        render json: response, status: :created
      else
        @errors = @receipt.errors.full_messages.uniq
        render json: {errors: @errors}, status: :unprocessable_entity
      end
    else
      @errors = [I18n.t("controller.receipts.errors.receipt_reference_id_already_exists", name: "#{params[:receipt][:reference_id]}")]
      render json: {errors: @errors}, status: :unprocessable_entity
    end
  end

  def reference_ids_present?
    if params[:action] == 'create'
      unless params.dig(:receipt, :reference_id).present?
        @errors = [I18n.t("controller.receipts.errors.reference_id_required")]
        render json: {errors: @errors}, status: :bad_request and return
      end
      unless params.dig(:receipt, :lead_id).present?
        @errors = [I18n.t("controller.receipts.errors.lead_id_required")]
        render json: {errors: @errors}, status: :bad_request and return
      end
    end
    if params.dig(:receipt, :user_kyc_attributes).present? && !params.dig(:receipt, :user_kyc_attributes, :reference_id).present?
      @errors = [I18n.t("controller.receipts.errors.user_kyc_reference_id_required")]
      render json: {errors: @errors}, status: :bad_request and return
    end
  end

  def set_lead
    @lead = Lead.where(booking_portal_client_id: @current_client.try(:id), "third_party_references.crm_id": @crm.id, "third_party_references.reference_id": params[:receipt][:lead_id]).first
    unless @lead.present?
      @errors = [I18n.t("controller.leads.errors.lead_reference_id_not_found", name: "#{params[:receipt][:lead_id]}")]
      render json: {errors: @errors}, status: :not_found and return
    end
  end

  def set_receipt_and_lead
    @receipt = Receipt.where(booking_portal_client_id: @current_client.try(:id), "third_party_references.crm_id": @crm.id, "third_party_references.reference_id": params[:id]).first
    @resource = @receipt if @receipt.present?
    unless @receipt.present?
      @errors = [I18n.t("controller.receipts.errors.receipt_reference_id_not_found", name: "#{params[:id]}")]
      render json: {errors: @errors}, status: :not_found and return
    end
    unless @receipt.success?
      @errors = [I18n.t("controller.receipts.errors.receipt_reference_id_in_success", name: "#{params[:id]}")]
      render json: {errors: @errors}, status: :unprocessable_entity and return
    end
    @lead = @receipt.lead
  end

  def check_user_kyc_params
    errors = []
    if kyc_attributes = params.dig(:receipt, :user_kyc_attributes)
      if @receipt.present? && @receipt.user_kyc.present?
        errors << I18n.t("controller.receipts.errors.user_kyc_present")
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
