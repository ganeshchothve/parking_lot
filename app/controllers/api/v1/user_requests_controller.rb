class Api::V1::UserRequestsController < ApisController
  before_action :reference_id_present?
  before_action :check_params, :set_resource_lead_user_and_project

  def create
    @user_request = ::UserRequest::Cancellation.new(requestable: @resource, created_by_id: @crm.user_id.to_s, resolved_by_id: @crm.user_id.to_s, lead_id: @lead.id.to_s, user_id: @user.id.to_s, project_id: @project.id.to_s)
    if @user_request.save && @user_request.processing!
      render json: { "#{@resource.class.to_s.underscore}_id": @resource.id, message: "#{@resource.class.to_s.titleize} has been sent for cancellation" }, status: :ok
    else
      render json: {errors: @user_request.errors.full_messages.uniq}, status: :unprocessable_entity
    end
  end

  private

  def reference_id_present?
    if params.dig(:user_request, :booking_detail_id).blank? && params.dig(:user_request, :receipt_id).blank?
      render json: { errors: ['Booking detail id or Receipt id is required for cancellation'] }, status: :bad_request and return
    end
  end

  def check_params
    render json: {errors: "User request type is required"}, status: :bad_request and return unless params.dig(:user_request, :type).present?
    render json: {errors: ["Only cancellation user request type is supported"]}, status: :bad_request and return if params.dig(:user_request, :type) != 'cancellation'
  end

  def set_resource_lead_user_and_project
    if booking_id = params.dig(:user_request, :booking_detail_id).presence
      @resource = BookingDetail.where("third_party_references.crm_id": @crm.id, "third_party_references.reference_id": booking_id).first
      render json: { errors: ["Booking Detail with reference_id '#{ booking_id }' not found"] }, status: :not_found and return unless @resource.present?
      render json: { errors: ["Booking Detail(#{ booking_id }) is not available for cancellation."]}, status: :unprocessable_entity and return unless %w[blocked booked_tentative booked_confirmed].include?(@resource.status)
    elsif receipt_id = params.dig(:user_request, :receipt_id).presence
      @resource = Receipt.where("third_party_references.crm_id": @crm.id, "third_party_references.reference_id": receipt_id).first
      render json: { errors: ["Receipt with reference_id '#{ receipt_id }' not found"] }, status: :not_found and return unless @resource.present?
      render json: { errors: ["Receipt(#{ receipt_id }) is not available for cancellation."]}, status: :unprocessable_entity and return unless %w[success].include?(@resource.status)
    end
    @lead = @resource.lead
    render json: {errors: ["Lead not present for booking. Please contact administrator"]}, status: :unprocessable_entity and return unless @lead.present?
    @user = @lead.user
    render json: {errors: ["User Account not present for lead. Please contact administrator"]}, status: :unprocessable_entity and return unless @user.present?
    @project = @lead.project
    render json: {errors: ["Project not present for lead. Please contact administrator"]}, status: :unprocessable_entity and return unless @project.present?
  end
end
