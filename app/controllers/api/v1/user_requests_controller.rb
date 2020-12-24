class Api::V1::UserRequestsController < ApisController
  before_action :reference_id_present?
  before_action :set_booking_detail_lead_user_and_project, :check_params

  def create
    @user_request = ::UserRequest::Cancellation.new(requestable: @booking_detail, created_by_id: @crm.user_id.to_s, resolved_by_id: @crm.user_id.to_s, lead_id: @lead.id.to_s, user_id: @user.id.to_s, project_id: @project.id.to_s)
    if @user_request.save && @user_request.processing!
      render json: {booking_detail_id: @booking_detail.id, message: "Booking Detail has been sent for cancellation"}, status: :ok
    else
      render json: {errors: @user_request.errors.full_messages.uniq}, status: :unprocessable_entity
    end
  end

  def reference_id_present?
    render json: { errors: ['Booking detail id is required for cancellation'] }, status: :bad_request and return unless params.dig(:user_request, :booking_detail_id).present?
  end

  def set_booking_detail_lead_user_and_project
    @booking_detail = BookingDetail.where("third_party_references.crm_id": @crm.id, "third_party_references.reference_id": params.dig(:user_request, :booking_detail_id)).first
    render json: { errors: ["Booking Detail with reference_id '#{ params.dig(:user_request, :booking_detail_id) }' not found"] }, status: :not_found and return unless @booking_detail.present?
    render json: { errors: ["Booking Detail(#{ params.dig(:user_request, :booking_detail_id) }) is not available for cancellation."]}, status: :unprocessable_entity and return unless %w[blocked booked_tentative booked_confirmed].include?(@booking_detail.status)
    @lead = @booking_detail.lead
    render json: {errors: ["Lead not present for booking. Please contact administrator"]}, status: :unprocessable_entity and return unless @lead.present?
    @user = @lead.user
    render json: {errors: ["User Account not present for lead. Please contact administrator"]}, status: :unprocessable_entity and return unless @user.present?
    @project = @lead.project
    render json: {errors: ["Project not present for lead. Please contact administrator"]}, status: :unprocessable_entity and return unless @project.present?
  end

  def check_params
    render json: {errors: "User request type is required"}, status: :bad_request and return unless params.dig(:user_request, :type).present?
    render json: {errors: ["Only cancellation user request type is supported"]}, status: :bad_request and return if params.dig(:user_request, :type) != 'cancellation'
  end
end
