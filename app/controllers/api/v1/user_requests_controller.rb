class Api::V1::UserRequestsController < ApisController
  before_action :reference_id_present?
  before_action :check_params, :set_requestable_lead_user_and_project

  def create
    @user_request = ::UserRequest::Cancellation.new(requestable: @requestable, created_by_id: @crm.user_id.to_s, resolved_by_id: @crm.user_id.to_s, lead_id: @lead.id.to_s, user_id: @user.id.to_s, project_id: @project.id.to_s)
    @user_request.booking_portal_client_id = @current_client.try(:id)
    @resource = @user_request
    if @user_request.save && @user_request.processing!
      @message = I18n.t("controller.user_requests.message.sent_for_cancellation", name: I18n.t("mongoid.models.#{@requestable.class.to_s}.other"))
      render json: { "#{@requestable.class.to_s.underscore}_id": @requestable.id, message: @message }, status: :ok
    else
      @errors = @user_request.errors.full_messages.uniq
      render json: {errors: @errors}, status: :unprocessable_entity
    end
  end

  private

  def reference_id_present?
    unless params.dig(:user_request, :booking_detail_id).present? || params.dig(:user_request, :receipt_id).present?
      @errors = [I18n.t("controller.user_requests.errors.ids_required_for_cancellation")]
      render json: { errors: @errors }, status: :bad_request and return
    end
  end

  def check_params
    unless params.dig(:user_request, :type).present?
      @errors = [I18n.t("controller.user_requests.errors.request_type_required")]
      render json: { errors: @errors }, status: :bad_request and return
    end
    if params.dig(:user_request, :type) != 'cancellation'
      @errors = [I18n.t("controller.user_requests.errors.cancellation_request_type_supported")]
      render json: { errors: @errors }, status: :bad_request and return
    end
  end

  def set_requestable_lead_user_and_project
    if booking_id = params.dig(:user_request, :booking_detail_id).presence
      @requestable = BookingDetail.where(booking_portal_client_id: @current_client.try(:id), "third_party_references.crm_id": @crm.id, "third_party_references.reference_id": booking_id).first
      unless @resource.present?
        @errors = [I18n.t("controller.booking_details.errors.booking_detail_reference_id_not_found", name: "#{ booking_id }")]
        render json: { errors: @errors }, status: :not_found and return
      end
      unless %w[blocked booked_tentative booked_confirmed scheme_approved].include?(@requestable.status)
        @errors = [I18n.t("controller.booking_details.errors.not_available_for_cancellation", name: "#{ booking_id }")]
        render json: { errors: @errors }, status: :unprocessable_entity and return
      end
    elsif receipt_id = params.dig(:user_request, :receipt_id).presence
      @requestable = Receipt.where(booking_portal_client_id: @current_client.try(:id), "third_party_references.crm_id": @crm.id, "third_party_references.reference_id": receipt_id).first
      unless @requestable.present?
        @errors = [I18n.t("controller.receipts.errors.receipt_reference_id_not_found", name: "#{ receipt_id }")]
        render json: { errors: @errors }, status: :not_found and return
      end
      unless %w[success].include?(@requestable.status)
        @errors = [I18n.t("controller.receipts.errors.not_available_for_cancellation", name: "#{ receipt_id }")]
        render json: { errors: @errors }, status: :unprocessable_entity and return
      end
    end
    @lead = @requestable.lead
    unless @lead.present?
      @errors = [I18n.t("controller.leads.errors.lead_not_present_for_booking")]
      render json: { errors: @errors }, status: :unprocessable_entity and return
    end
    @user = @lead.user
    unless @user.present?
      @errors = [I18n.t("controller.leads.errors.user_account_not_present_for_lead")]
      render json: { errors: @errors }, status: :unprocessable_entity and return
    end
    @project = @lead.project
    unless @project.present?
      @errors = [I18n.t("controller.leads.errors.project_not_present_for_lead")]
      render json: { errors: @errors }, status: :unprocessable_entity and return
    end
  end
end
