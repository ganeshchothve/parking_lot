class Api::V1::BookingDetailsController < ApisController
  include Api::UserKycsConcern
  include Api::ReceiptsConcern
  before_action :reference_ids_present?
  before_action :set_project_unit, :set_lead, :check_project, :check_scheme, only: :create
  before_action :set_booking_detail_project_unit_and_lead, only: :update
  before_action :add_third_party_reference_params, :check_params, :modify_params

  def create
    unless BookingDetail.reference_resource_exists?(@crm.id, params[:booking_detail][:reference_id].to_s)
      build_booking_detail
      @booking_detail.assign_attributes(booking_detail_create_params)
      if @booking_detail.save
        if @booking_detail.under_negotiation!
          response = generate_response
          response[:message] = 'Booking successfully created.'
          render json: response, status: :created
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
    unless BookingDetail.reference_resource_exists?(@crm.id, params[:booking_detail][:reference_id].to_s)
      @booking_detail.assign_attributes(booking_detail_update_params)
      if @booking_detail.save
        response = generate_response
        response[:message] = 'Booking successfully updated.'
        render json: response, status: :ok
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
    end
    params.dig(:booking_detail, :user_kycs_attributes).each do |user_kyc_attributes|
      render json: { errors: ['User KYC reference id is required for all user KYCs'] }, status: :bad_request and return unless user_kyc_attributes.dig(:reference_id).present?
    end if params.dig(:booking_detail, :user_kycs_attributes).present?
  end

  def set_lead
    @lead = Lead.where("third_party_references.crm_id": @crm.id, "third_party_references.reference_id": params[:booking_detail][:lead_id]).first
    render json: { errors: ["Lead with reference_id '#{ params[:booking_detail][:lead_id] }' not found"] }, status: :not_found and return unless @lead
  end

  def set_project_unit
    @project_unit = ProjectUnit.where("third_party_references.crm_id": @crm.id, "third_party_references.reference_id": params[:booking_detail][:project_unit_id], status: 'available').first
    render json: { errors: ["Project Unit with reference_id '#{ params[:booking_detail][:project_unit_id] }' not found or is already booked"] }, status: :not_found and return unless @project_unit
  end

  def check_project
    render json: { errors: ["Project for project unit - #{ params[:booking_detail][:project_unit_id] } and lead - #{ params[:booking_detail][:lead_id] } does not match"] }, status: :not_found and return if @lead.project_id != @project_unit.project_id
  end

  def check_scheme
    unless @lead.manager_role?('channel_partner')
      scheme = @project_unit.project_tower.default_scheme
    else
      filters = {fltrs: { can_be_applied_by_role: @lead.manager_role, project_tower: @project_unit.project_tower_id, user_role: @lead.user_role, user_id: @lead.user_id, status: 'approved', default_for_user_id: @lead.manager_id } }
      scheme = Scheme.build_criteria(filters).first
    end
    render json: { errors: ["Booking scheme is not found for this project unit. Please contact administrator"] }, status: :not_found and return unless scheme.present?
  end

  def build_booking_detail
     @booking_detail = BookingDetail.new(
                                          name: @project_unit.name,
                                          base_rate: @project_unit.base_rate,
                                          project_name:  @project_unit.project_name,
                                          project_tower_name: @project_unit.project_tower_name,
                                          bedrooms: @project_unit.bedrooms,
                                          bathrooms: @project_unit.bathrooms,
                                          floor_rise: @project_unit.floor_rise,
                                          #saleable: @project_unit.saleable,
                                          costs: @project_unit.costs,
                                          data: @project_unit.data,
                                          project_unit_id: @project_unit.id,
                                          lead_id: @lead.id, user_id: @lead.user.id,
                                          project_id: @project_unit.project_id
                                        )
  end

  def set_booking_detail_project_unit_and_lead
    @booking_detail = BookingDetail.where("third_party_references.crm_id": @crm.id, "third_party_references.reference_id": params[:id]).first
    render json: { errors: ["Booking Detail with reference_id '#{ params[:id] }' not found"] }, status: :not_found and return unless @booking_detail.present?
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

  def check_booking_detail_params
    errors = []
    begin
      Date.strptime( params.dig(:booking_detail, :booked_on), "%d/%m/%Y") if params.dig(:booking_detail, :booked_on).present?
    rescue ArgumentError
      errors << "booked_on date format is invalid. Correct date format is - dd/mm/yyyy"
    end
    { "Booking detail errors - ": errors.try(:compact) } if errors.try(:compact).present?
  end

  def check_primary_user_kyc_params
    errors = []
    if kyc_attributes = params.dig(:booking_detail, :primary_user_kyc_attributes)
      if @booking_detail.present? && @booking_detail.primary_user_kyc.present?
        errors << "Primary User KYC is already present for booking detail"
        return { "Primary user kycs errors - ": errors.try(:compact) }
      end
      errors << check_any_user_kyc_params(kyc_attributes)
    end
    { "Primary user kycs errors - ": errors.try(:compact) } if errors.try(:compact).present?
  end

  def check_user_kycs_params
    errors = []
    params[:booking_detail][:user_kycs_attributes].each_with_index do |kyc_attributes, i|
      errors << check_any_user_kyc_params(kyc_attributes)
    end if params[:booking_detail][:user_kycs_attributes].present?
    { "User Kycs errors - ": errors.try(:compact) } if errors.try(:compact).present?
  end

  def check_receipts_params
    errors = []
    params[:booking_detail][:receipts_attributes].each_with_index do |receipt_attributes, i|
      errors << check_any_receipt_params(receipt_attributes)
    end if params[:booking_detail][:receipts_attributes].present?
    { "Receipts errors": errors.compact } if errors.try(:compact).present?
  end

  def check_task_params
    errors = []
    if params[:booking_detail][:tasks_attributes].present?
      if tasks_attributes = params[:booking_detail][:tasks_attributes].try(:permit!).try(:to_h)
        @client = @lead.user.booking_portal_client
        tasks_attributes.each do |task, value|
          errors << check_any_task_params(task.to_s, value)
        end
      else
        errors << 'tasks_attributes should be a key, value pair'
      end
    end
    { "Tasks errors": errors.compact } if errors.try(:compact).present?
  end

  def check_any_task_params task, value
    errors = []
    errors << "No task found" if (@booking_detail.present? && @booking_detail.tasks.where(key: task).blank?) && @client.checklists.where(key: task).blank?
    { task => errors } if errors.present?
  end

  def check_params
    errors = []
    errors << check_booking_detail_params
    errors << check_primary_user_kyc_params
    errors << check_user_kycs_params
    errors << check_receipts_params
    errors << check_task_params
    render json: { errors: errors.compact }, status: :unprocessable_entity and return if errors.try(:compact).present?
  end

  def modify_params
    #modify booking_detail params
    params[:booking_detail][:booked_on] = Date.strptime( params[:booking_detail][:booked_on], "%d/%m/%Y") if params.dig(:booking_detail, :booked_on).present?
    #modify primary_user_kyc_params
    params[:booking_detail][:primary_user_kyc_attributes] = modify_any_user_kyc_params(params.dig(:booking_detail, :primary_user_kyc_attributes))

    # modify user kyc params
    params[:booking_detail][:user_kycs_attributes].each_with_index do |kyc_attributes, i|
      params[:booking_detail][:user_kycs_attributes][i] = modify_any_user_kyc_params(kyc_attributes)
    end if params[:booking_detail][:user_kycs_attributes].present?

    # modify receipts params
    params[:booking_detail][:receipts_attributes].each_with_index do |receipt_attributes, i|
      params[:booking_detail][:receipts_attributes][i] = modify_any_receipt_params(receipt_attributes)
    end if params[:booking_detail][:receipts_attributes].present?

    # modify tasks params
    params[:booking_detail][:tasks_attributes] = params[:booking_detail][:tasks_attributes].permit!.to_h.map do |task, value|
      if @booking_detail.present? && booking_task = @booking_detail.tasks.where(key: task).first
        { id: booking_task.id.to_s, completed: value, completed_by_id: @crm.user_id.to_s }
      elsif booking_task = @client.checklists.where(key: task).first
        { name: booking_task.name, key: booking_task.key, tracked_by: booking_task.tracked_by, order: booking_task.order, completed: value, completed_by_id: @crm.user_id.to_s }
      end
    end.compact if params[:booking_detail][:tasks_attributes].present?
  end

  def receipt_params
    [:project_id, :lead_id, :user_id, :payment_mode, :issued_date, :issuing_bank, :issuing_bank_branch, :payment_identifier, :tracking_id, :total_amount, :status_message, :payment_gateway, :processed_on, :comments, :payment_type, :creator_id, third_party_references_attributes: [:id, :crm_id, :reference_id]]
  end

  def user_kyc_params
    [:lead_id, :salutation, :first_name, :last_name, :email, :phone, :dob, :pan_number, :aadhaar, :anniversary, :education_qualification, :designation, :customer_company_name, :number_of_units, :budget, :comments, :nri, :oci, :poa, :poa_details, :poa_details_phone_no, :is_company, :gstn, :company_name, :existing_customer, :existing_customer_name, :existing_customer_project, :creator_id,  third_party_references_attributes: [:id, :crm_id, :reference_id], preferred_floors: [], configurations: [], addresses_attributes: [:id, :one_line_address, :address1, :address2, :city, :state, :country, :country_code, :zip, :primary, :address_type]]
  end

  def tasks_params
    [:id, :name, :key, :tracked_by, :order, :completed, :completed_by_id]
  end

  def booking_detail_create_params
    params.require(:booking_detail).permit(:agreement_price, :all_inclusive_price, :carpet, :saleable, :blocking_amount, :booked_on, receipts_attributes: receipt_params, primary_user_kyc_attributes: user_kyc_params, user_kycs_attributes: user_kyc_params, tasks_attributes: tasks_params, third_party_references_attributes: [:id, :reference_id, :crm_id])
  end

  def booking_detail_update_params
    params.require(:booking_detail).permit( receipts_attributes: receipt_params, user_kycs_attributes: user_kyc_params, tasks_attributes: tasks_params, third_party_references_attributes: [:id, :reference_id])
  end

  def get_receipts_ids
    receipt_ids = {}
    receipts_statuses = %w[clearance_pending success]
    params.dig(:booking_detail, :receipts_attributes).each do |receipt_attributes|
      receipt = @lead.receipts.where("third_party_references.crm_id": @crm.id, "third_party_references.reference_id": receipt_attributes.dig(:reference_id).to_s ).first
      receipt_ids[receipt_attributes.dig(:reference_id).to_s] =  {id: receipt.try(:id).to_s}
      if receipt.present?
        receipts_statuses.each do |event|
          receipt.assign_attributes(event: event)
          unless receipt.save
            errors = receipt.state_machine_errors + receipt.errors.to_a
            receipt.set(state_machine_errors: errors)
          end
          break if receipt_attributes[:status] == event
        end if receipt_attributes[:status].present? && receipt_attributes[:status].to_s.in?(receipts_statuses)
        receipt_ids[receipt_attributes.dig(:reference_id).to_s][:status_change_errors] = receipt.state_machine_errors if receipt.state_machine_errors.present?
      end
    end
    receipt_ids
  end

  def get_user_kycs_ids
    user_kyc_ids = {}
    params.dig(:booking_detail, :user_kycs_attributes).each do |user_kyc_attributes|
      user_kyc_ids[user_kyc_attributes.dig(:reference_id).to_s] =  @lead.user_kycs.where("third_party_references.crm_id": @crm.id, "third_party_references.reference_id": user_kyc_attributes.dig(:reference_id).to_s ).first.try(:id).to_s
    end
    user_kyc_ids
  end

  def generate_response
    response = {booking_detail_id: @booking_detail.id.to_s}
    response[:primary_user_kyc_id] = @booking_detail.primary_user_kyc_id.to_s if params.dig(:booking_detail, :primary_user_kyc_attributes).present?
    response[:receipt_ids] = get_receipts_ids if params.dig(:booking_detail, :receipts_attributes).present?
    response[:user_kyc_ids] = get_user_kycs_ids if params.dig(:booking_detail, :user_kycs_attributes).present?
    response
  end
end
