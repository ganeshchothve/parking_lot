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
    unless params.dig(:user_request, :booking_detail_id).present? || params.dig(:user_request, :receipt_id).present?
      render json: { errors: [I18n.t("controller.user_requests.errors.id_required")] }, status: :bad_request and return
    end
  end

  def check_params
    render json: {errors: I18n.t("controller.user_requests.errors.request_type_required")}, status: :bad_request and return unless params.dig(:user_request, :type).present?
    render json: {errors: [I18n.t("controller.user_requests.errors.supported_request_type")]}, status: :bad_request and return if params.dig(:user_request, :type) != 'cancellation'
  end

  def set_resource_lead_user_and_project
    if booking_id = params.dig(:user_request, :booking_detail_id).presence
      @resource = BookingDetail.where("third_party_references.crm_id": @crm.id, "third_party_references.reference_id": booking_id).first
      render json: { errors: [I18n.t("controller.errors.reference_id_not_found", name1:"Booking Detail", name2:"#{booking_id}")] }, status: :not_found and return unless @resource.present?
      render json: { errors: [I18n.t("controller.errors.not_available_for_cancellation", name: "Booking Detail(#{ booking_id })")]}, status: :unprocessable_entity and return unless %w[blocked booked_tentative booked_confirmed scheme_approved].include?(@resource.status)
    elsif receipt_id = params.dig(:user_request, :receipt_id).presence
      @resource = Receipt.where("third_party_references.crm_id": @crm.id, "third_party_references.reference_id": receipt_id).first
      render json: { errors: [I18n.t("controller.errors.reference_id_not_found", name1:"Receipt", name2:"#{ receipt_id }")] }, status: :not_found and return unless @resource.present?
      render json: { errors: [I18n.t("controller.errors.not_available_for_cancellation", name:"Receipt(#{ receipt_id })")]}, status: :unprocessable_entity and return unless %w[success].include?(@resource.status)
    end
    @lead = @resource.lead
    render json: {errors: [I18n.t("controller.errors.not_present_for", name1:"Lead", name2: "Booking")]}, status: :unprocessable_entity and return unless @lead.present?
    @user = @lead.user
    render json: {errors: [I18n.t("controller.errors.not_present_for", name1:"User Account", name2: "Lead")]}, status: :unprocessable_entity and return unless @user.present?
    @project = @lead.project
    render json: {errors: [I18n.t("controller.errors.not_present_for", name1:"Project", name2: "Lead")]}, status: :unprocessable_entity and return unless @project.present?
  end
end
