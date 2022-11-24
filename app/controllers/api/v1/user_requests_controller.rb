class Api::V1::UserRequestsController < ApisController
  before_action :reference_id_present?
  before_action :check_params, :set_resource_lead_user_and_project

  def create
    @user_request = ::UserRequest::Cancellation.new(requestable: @resource, created_by_id: @crm.user_id.to_s, resolved_by_id: @crm.user_id.to_s, lead_id: @lead.id.to_s, user_id: @user.id.to_s, project_id: @project.id.to_s)
    @user_request.booking_portal_client_id = @current_client.try(:id)
    if @user_request.save && @user_request.processing!
      render json: { "#{@resource.class.to_s.underscore}_id": @resource.id, message: I18n.t("controller.user_requests.message.sent_for_cancellation", name: I18n.t("mongoid.models.#{@resource.class.to_s}.other")) }, status: :ok
    else
      render json: {errors: @user_request.errors.full_messages.uniq}, status: :unprocessable_entity
    end
  end

  private

  def reference_id_present?
    unless params.dig(:user_request, :booking_detail_id).present? || params.dig(:user_request, :receipt_id).present?
      render json: { errors: [I18n.t("controller.user_requests.errors.ids_required_for_cancellation")] }, status: :bad_request and return
    end
  end

  def check_params
    render json: {errors: I18n.t("controller.user_requests.errors.request_type_required")}, status: :bad_request and return unless params.dig(:user_request, :type).present?
    render json: {errors: [I18n.t("controller.user_requests.errors.cancellation_request_type_supported")]}, status: :bad_request and return if params.dig(:user_request, :type) != 'cancellation'
  end

  def set_resource_lead_user_and_project
    if booking_id = params.dig(:user_request, :booking_detail_id).presence
      @resource = BookingDetail.where(booking_portal_client_id: @current_client.try(:id), "third_party_references.crm_id": @crm.id, "third_party_references.reference_id": booking_id).first
      render json: { errors: [I18n.t("controller.booking_details.errors.booking_detail_reference_id_not_found", name: "#{ booking_id }")] }, status: :not_found and return unless @resource.present?
      render json: { errors: [I18n.t("controller.booking_details.errors.not_available_for_cancellation", name: "#{ booking_id }")]}, status: :unprocessable_entity and return unless %w[blocked booked_tentative booked_confirmed scheme_approved].include?(@resource.status)
    elsif receipt_id = params.dig(:user_request, :receipt_id).presence
      @resource = Receipt.where(booking_portal_client_id: @current_client.try(:id), "third_party_references.crm_id": @crm.id, "third_party_references.reference_id": receipt_id).first
      render json: { errors: [I18n.t("controller.receipts.errors.receipt_reference_id_not_found", name: "#{ receipt_id }")] }, status: :not_found and return unless @resource.present?
      render json: { errors: [I18n.t("controller.receipts.errors.not_available_for_cancellation", name: "#{receipt_id}")]}, status: :unprocessable_entity and return unless %w[success].include?(@resource.status)
    end
    @lead = @resource.lead
    render json: {errors: [I18n.t("controller.leads.errors.lead_not_present_for_booking")]}, status: :unprocessable_entity and return unless @lead.present?
    @user = @lead.user
    render json: {errors: [I18n.t("controller.leads.errors.user_account_not_present_for_lead")]}, status: :unprocessable_entity and return unless @user.present?
    @project = @lead.project
    render json: {errors: [I18n.t("controller.leads.errors.project_not_present_for_lead")]}, status: :unprocessable_entity and return unless @project.present?
  end
end
