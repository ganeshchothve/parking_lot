class Api::V1::BookingDetailsController < ApisController
  before_action :reference_ids_present?
  before_action :set_project_unit, :set_lead, :check_project, :check_scheme, only: :create
  before_action :set_booking_detail_project_unit_and_lead, only: :update
  before_action :add_third_party_reference_params, :modify_params

  def create
    unless BookingDetail.reference_resource_exists?(@crm.id, params[:booking_detail][:reference_id])
      @booking_detail = BookingDetail.new(name: @project_unit.name, base_rate: @project_unit.base_rate, floor_rise: @project_unit.floor_rise, saleable: @project_unit.saleable, costs: @project_unit.costs, data: @project_unit.data, project_unit_id: @project_unit.id, lead_id: @lead.id, user_id: @lead.user.id, project_id: @project_unit.project_id)
      @booking_detail.assign_attributes(booking_detail_create_params)
      if @booking_detail.save
        if @booking_detail.under_negotiation!
        response = generate_response
        response[:message] = 'Booking successfully created.'
        render json: response, status: :created
          # render json: {generate_response, message: 'Booking successfully created.'}, status: :created
        else
          render json: {errors: @booking_detail.errors.full_messages.uniq}, status: :unprocessable_entity
        end
      else
        render json: {errors: @booking_detail.errors.full_messages.uniq}, status: :unprocessable_entity
      end
    else
      render json: {errors: ["Booking with reference_id '#{params[:booking_detail][:reference_id]}' already exists"]}, status: :unprocessable_entity
    end
  end

  def update
    unless BookingDetail.reference_resource_exists?(@crm.id, params[:booking_detail][:reference_id])
      @booking_detail.assign_attributes(booking_detail_update_params)
      if @booking_detail.save
        response = generate_response
        response[:message] = 'Booking successfully updated.'
        render json: response, status: :created
      else
        render json: {errors: @booking_detail.errors.full_messages.uniq}, status: :unprocessable_entity
      end
    else
      render json: {errors: ["Booking with reference_id '#{params[:booking_detail][:reference_id]}' already exists"]}, status: :unprocessable_entity
    end
  end

  def reference_ids_present?
    if params[:action] == 'create'
      render json: { errors: ['reference_id is required to create Booking'] }, status: :bad_request and return unless params.dig(:booking_detail, :reference_id).present?
      render json: { errors: ['project_unit_id is required to create Booking'] }, status: :bad_request and return unless params.dig(:booking_detail, :project_unit_id).present?
      render json: { errors: ['Lead_id is required to create Booking'] }, status: :bad_request and return unless params.dig(:booking_detail, :lead_id).present?
    end
    render json: { errors: ['Primary user kyc reference id is required to create Booking'] }, status: :bad_request and return if params.dig(:booking_detail, :primary_user_kyc_attributes).present? && !params.dig(:booking_detail, :primary_user_kyc_attributes, :reference_id).present?
    if params.dig(:booking_detail, :receipts_attributes).present?
      params.dig(:booking_detail, :receipts_attributes).each do |receipt_attributes|
        render json: { errors: ['Receipt reference id is required for all receipts'] }, status: :bad_request and return unless receipt_attributes.dig(:reference_id).present?
      end
    else
      render json: {errors: ['Receipts is/are mandatory to create Booking']} if params[:action] == 'create'
    end
    params.dig(:booking_detail, :user_kycs_attributes).each do |user_kyc_attributes|
      render json: { errors: ['User KYC reference id is required for all user KYCs'] }, status: :bad_request and return unless user_kyc_attributes.dig(:reference_id).present?
    end if params.dig(:booking_detail, :user_kycs_attributes).present?
  end

  def set_lead
    @lead = Lead.where("third_party_references.crm_id": @crm.id, "third_party_references.reference_id": params[:booking_detail][:lead_id]).first
    render json: { errors: ["Lead with reference_id '#{ params[:booking_detail][:lead_id] }' not found"] }, status: :not_found unless @lead
  end

  def set_project_unit
    @project_unit = ProjectUnit.where("third_party_references.crm_id": @crm.id, "third_party_references.reference_id": params[:booking_detail][:project_unit_id], status: 'available').first
    render json: { errors: ["Project Unit with reference_id '#{ params[:booking_detail][:project_unit_id] }' not found or is already booked"] }, status: :not_found unless @project_unit
  end

  def check_project
    render json: { errors: ["Project for project unit - #{ params[:booking_detail][:project_unit_id] } and lead - #{ params[:booking_detail][:lead_id] } does not match"] }, status: :not_found if @lead.project_id != @project_unit.project_id
  end

  def check_scheme
    unless @lead.manager_role?('channel_partner')
      scheme = @project_unit.project_tower.default_scheme
    else
      filters = {fltrs: { can_be_applied_by_role: @lead.manager_role, project_tower: @project_unit.project_tower_id, user_role: @lead.user_role, user_id: @lead.user_id, status: 'approved', default_for_user_id: @lead.manager_id } }
      scheme = Scheme.build_criteria(filters).first
    end
    render json: { errors: ["Booking scheme is not found for this project unit. Please contact administrator"] }, status: :not_found unless scheme.present?
  end

  def set_booking_detail_project_unit_and_lead
    @booking_detail = BookingDetail.where("third_party_references.crm_id": @crm.id, "third_party_references.reference_id": params[:id]).first
    render json: { errors: ["Booking Detail with reference_id '#{ params[:id] }' not found"] }, status: :not_found unless @booking_detail.present?
    @lead = @booking_detail.lead
    @project_unit = @booking_detail.project_unit
  end

  def add_third_party_reference_params
    if booking_detail_reference_id = params.dig(:booking_detail, :reference_id).presence
      # add third party references
      tpr_attrs = {
        crm_id: @crm.id.to_s,
        reference_id: booking_detail_reference_id
      }
      if @booking_detail
        tpr = @booking_detail.third_party_references.where(reference_id: params[:id], crm_id: @crm.id).first
        tpr_attrs[:id] = tpr.id.to_s if tpr
      end
      params[:booking_detail][:third_party_references_attributes] = [ tpr_attrs ]
    end
  end

  def modify_primary_user_kyc_params
    errors = []
    if params[:booking_detail][:primary_user_kyc_attributes].present?
      if @booking_detail.present? && @booking_detail.primary_user_kyc.present?
        errors << "Primary User KYC is already present for booking detail"
        return "Primary user kycs errors - " + errors.to_sentence
      end
      begin
        params[:booking_detail][:primary_user_kyc_attributes][:dob] = Date.strptime(params[:booking_detail][:primary_user_kyc_attributes][:dob], "%d/%m/%Y") if params[:booking_detail][:primary_user_kyc_attributes][:dob].present?
      rescue ArgumentError
        errors << 'DOB date format is invalid. Correct date format is - dd/mm/yyyy'
      end
      begin
        params[:booking_detail][:primary_user_kyc_attributes][:anniversary] = Date.strptime(params[:booking_detail][:primary_user_kyc_attributes][:anniversary], "%d/%m/%Y") if params[:booking_detail][:primary_user_kyc_attributes][:anniversary].present?
      rescue ArgumentError
        errors << 'Anniversay date format is invalid. Correct date format is - dd/mm/yyyy'
      end
      errors << "NRI should be a boolean value - true or false" if params[:booking_detail][:primary_user_kyc_attributes][:nri].present? && !params[:booking_detail][:primary_user_kyc_attributes][:nri].is_a?(Boolean)
      errors << "POA should be a boolean value - true or false" if params[:booking_detail][:primary_user_kyc_attributes][:nri].present? && !params[:booking_detail][:primary_user_kyc_attributes][:poa].is_a?(Boolean)
      errors << "Is Company should be a boolean value - true or false" if params[:booking_detail][:primary_user_kyc_attributes][:nri].present? && !params[:booking_detail][:primary_user_kyc_attributes][:is_company].is_a?(Boolean)
      errors << "Existing customer should be a boolean value - true or false" if params[:booking_detail][:primary_user_kyc_attributes][:nri].present? && !params[:booking_detail][:primary_user_kyc_attributes][:existing_customer].is_a?(Boolean)
      errors << "Number of units should be an integer" if params[:booking_detail][:primary_user_kyc_attributes][:nri].present? && !params[:booking_detail][:primary_user_kyc_attributes][:number_of_units].is_a?(Integer)
      errors << "Budget should be an integer" if params[:booking_detail][:primary_user_kyc_attributes][:nri].present? && !params[:booking_detail][:primary_user_kyc_attributes][:budget].is_a?(Integer)
      params[:booking_detail][:primary_user_kyc_attributes][:lead_id] = @lead.id.to_s
      params[:booking_detail][:primary_user_kyc_attributes][:user_id] = @lead.user.id.to_s
      render json: { errors: errors }, status: :unprocessable_entity and return if errors.present?
      if primary_kyc_reference_id = params.dig(:booking_detail, :primary_user_kyc_attributes, :reference_id).presence
      # add third party references
        tpr_attrs = {
          crm_id: @crm.id.to_s,
          reference_id: primary_kyc_reference_id
        }
        params[:booking_detail][:primary_user_kyc_attributes][:third_party_references_attributes] = [ tpr_attrs ]
      end
    end
    if errors.present?
      "Primary user kycs errors - " + errors.to_sentence
    else
      nil
    end
  end

  def modify_user_kycs_params
    errors = []
    params[:booking_detail][:user_kycs_attributes].each_with_index do |kyc_attrs, i|
      begin
        params[:booking_detail][:user_kycs_attributes][i][:dob] = Date.strptime(params[:booking_detail][:user_kycs_attributes][i][:dob], "%d/%m/%Y") if params[:booking_detail][:user_kycs_attributes][i][:dob].present?
      rescue ArgumentError
        errors << 'DOB date format is invalid. Correct date format is - dd/mm/yyyy'
      end
      begin
        params[:booking_detail][:user_kycs_attributes][i][:anniversary] = Date.strptime(params[:booking_detail][:user_kycs_attributes][i][:anniversary], "%d/%m/%Y") if params[:booking_detail][:user_kycs_attributes][i][:anniversary].present?
      rescue ArgumentError
        errors << 'Anniversay date format is invalid. Correct date format is - dd/mm/yyyy'
      end
      errors << "NRI should be a boolean value - true or false" if !params[:booking_detail][:user_kycs_attributes][i][:nri].is_a?(Boolean)
      errors << "POA should be a boolean value - true or false" if !params[:booking_detail][:user_kycs_attributes][i][:poa].is_a?(Boolean)
      errors << "Is Company should be a boolean value - true or false" if !params[:booking_detail][:user_kycs_attributes][i][:is_company].is_a?(Boolean)
      errors << "Existing customer should be a boolean value - true or false" if !params[:booking_detail][:user_kycs_attributes][i][:existing_customer].is_a?(Boolean)
      errors << "Number of units should be an integer" if !params[:booking_detail][:user_kycs_attributes][i][:number_of_units].is_a?(Integer)
      errors << "Budget should be an integer" if !params[:booking_detail][:user_kycs_attributes][i][:budget].is_a?(Integer)
      params[:booking_detail][:user_kycs_attributes][i][:lead_id] = @lead.id.to_s
      render json: { errors: errors }, status: :unprocessable_entity and return if errors.present?
      if kyc_reference_id = params.dig(:booking_detail, :user_kycs_attributes, i, :reference_id).presence
      # add third party references
        # tpr_attrs = {
        #   crm_id: @crm.id.to_s,
        #   reference_id: kyc_reference_id
        # }
        # params[:booking_detail][:user_kycs_attributes][i][:third_party_references_attributes] = [ tpr_attrs ]
      end
    end if params[:booking_detail][:user_kycs_attributes].present?
    if errors.present?
      "User Kycs errors - " + errors.to_sentence
    else
      nil
    end
  end

  def modify_receipts_params
    errors = []
    params[:booking_detail][:receipts_attributes].each_with_index do |kyc_attrs, i|
      errors << "Receipt id is mandatory for receipt - #{params[:booking_detail][:receipts_attributes][i][:reference_id]}" unless params[:booking_detail][:receipts_attributes][i][:reference_id].present?        
      begin
        params[:booking_detail][:receipts_attributes][i][:issued_date] = Date.strptime(params[:booking_detail][:receipts_attributes][i][:issued_date], "%d/%m/%Y") if params[:booking_detail][:receipts_attributes][i][:issued_date].present?
      rescue ArgumentError
        errors << "Issued date format is invalid for receipt - #{params[:booking_detail][:receipts_attributes][i][:reference_id]}. Correct date format is - dd/mm/yyyy"
      end
      begin
        params[:booking_detail][:receipts_attributes][i][:processed_on] = Date.strptime(params[:booking_detail][:receipts_attributes][i][:processed_on], "%d/%m/%Y") if params[:booking_detail][:receipts_attributes][i][:processed_on].present?
      rescue ArgumentError
        errors << "Processed on date format is invalid for receipt - #{params[:booking_detail][:receipts_attributes][i][:reference_id]}. Correct date format is - dd/mm/yyyy"
      end
      if params[:booking_detail][:receipts_attributes][i][:status].present?
        errors << "Status should be clearance_pending or success" unless %w[clearance_pending success].include?( params[:booking_detail][:receipts_attributes][i][:status])
      else
        params[:booking_detail][:receipts_attributes][i][:status] = "clearance_pending"
      end
      # TO - DO Move this to receipt observer 
      params[:booking_detail][:receipts_attributes][i][:lead_id] = @lead.id.to_s
      params[:booking_detail][:receipts_attributes][i][:user_id] = @lead.user.id.to_s
      params[:booking_detail][:receipts_attributes][i][:project_id] = @lead.project.id.to_s
      params[:booking_detail][:receipts_attributes][i][:creator_id] = @crm.user_id.to_s
      # add third party references
      if receipt_reference_id = params.dig(:booking_detail, :receipts_attributes, i, :reference_id).presence
        tpr_attrs = {
          crm_id: @crm.id.to_s,
          reference_id: receipt_reference_id
        }
      end
      params[:booking_detail][:receipts_attributes][i][:third_party_references_attributes] = [ tpr_attrs ]
    end if params[:booking_detail][:receipts_attributes].present?
    if errors.present?
      "Receipts errors - " + errors.to_sentence
    else
      nil
    end
  end

  def modify_params
    errors = []
    errors << modify_primary_user_kyc_params
    errors << modify_user_kycs_params
    errors << modify_receipts_params
    render json: { errors: errors.flatten.compact }, status: :unprocessable_entity and return if errors.flatten.compact.present?
  end

  def receipt_params
    [:project_id, :lead_id, :user_id, :receipt_id, :order_id, :payment_mode, :issued_date, :issuing_bank, :issuing_bank_branch, :payment_identifier, :tracking_id, :total_amount, :status_message, :payment_gateway, :processed_on, :comments, :payment_type, :creator_id, third_party_references_attributes: [:id, :crm_id, :reference_id]]
  end

  def user_kyc_params
    [:lead_id, :salutation, :first_name, :last_name, :email, :phone, :dob, :pan_number, :aadhaar, :anniversary, :education_qualification, :designation, :customer_company_name, :number_of_units, :budget, :comments, :nri, :oci, :poa, :poa_details, :poa_details_phone_no, :is_company, :gstn, :company_name, :existing_customer, :existing_customer_name, :existing_customer_project,  third_party_references_attributes: [:id, :crm_id, :reference_id], preferred_floors: [], configurations: [], addresses_attributes: [:id, :one_line_address, :address1, :address2, :city, :state, :country, :country_code, :zip, :primary, :address_type]]
  end

  def booking_detail_create_params
    params.require(:booking_detail).permit( receipts_attributes: receipt_params, primary_user_kyc_attributes: user_kyc_params, user_kycs_attributes: user_kyc_params, third_party_references_attributes: [:id, :reference_id, :crm_id])
  end

  def booking_detail_update_params
    params.require(:booking_detail).permit( receipts_attributes: receipt_params, user_kycs_attributes: user_kyc_params, third_party_references_attributes: [:id, :reference_id])
  end

  def generate_response
    response = {booking_detail_id: @booking_detail.id.to_s}
    response[:primary_user_kyc_id] = @booking_detail.primary_user_kyc_id.to_s if params.dig(:booking_detail, :primary_user_kyc_attributes).present?
    receipt_ids = {}
    receipts_statuses = %w[clearance_pending success]
    params.dig(:booking_detail, :receipts_attributes).each do |receipt_attributes|
      receipt = Receipt.where("third_party_references.crm_id": @crm.id, "third_party_references.reference_id": receipt_attributes.dig(:reference_id).to_s ).first
      receipts_statuses.each do |event|
        receipt.assign_attributes(event: event)
        unless receipt.save
          errors = receipt.state_machine_errors + receipt.errors
          receipt.assign_attributes(state_machine_errors: errors)
          receipt.save
        end
        break if receipt_attributes[:status] == event
      end
      receipt_ids[receipt_attributes.dig(:reference_id).to_s] =  receipt.id.to_s
    end if params.dig(:booking_detail, :receipts_attributes).present?
    response[:receipt_ids] = receipt_ids if receipt_ids.present?
    user_kyc_ids = {}
    params.dig(:booking_detail, :user_kycs_attributes).each do |user_kyc_attributes|
      user_kyc_ids[user_kyc_attributes.dig(:reference_id).to_s] =  UserKyc.where("third_party_references.crm_id": @crm.id, "third_party_references.reference_id": user_kyc_attributes.dig(:reference_id).to_s ).first.id.to_s
    end if params.dig(:booking_detail, :user_kycs_attributes).present?
    response[:user_kyc_ids] = user_kyc_ids if user_kyc_ids.present?
    response
  end
end