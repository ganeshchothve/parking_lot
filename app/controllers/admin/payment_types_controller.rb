class Admin::PaymentTypesController < AdminController

  before_action :set_payment_type, only: %i[show edit update]

  def index
    @payment_types = PaymentType.where(booking_portal_client_id: current_client.try(:id)).build_criteria params
    if params[:fltrs].present? && params[:fltrs][:_id].present?
      redirect_to admin_payment_type_path(params[:fltrs][:_id])
    else
      @payment_types = @payment_types.paginate(page: params[:page] || 1, per_page: params[:per_page])
    end
    render 'admin/payment_types/index'
  end

  def new
    @payment_type = PaymentType.new(booking_portal_client_id: current_client.try(:id))
    render layout: false
  end

  def edit
    render layout: false
  end

  def show
    render 'admin/payment_types/show', layout: false
  end


  def update
    attrs = permitted_attributes([current_user_role_group, @payment_type])
    @payment_type.assign_attributes(attrs)
    @payment_type.booking_portal_client_id = current_client.try(:id)
    respond_to do |format|
      if @payment_type.save
        format.json { render json: @payment_type }
      else
        format.json { render json: { errors: @payment_type.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end

  def create
    @payment_type = PaymentType.new(booking_portal_client_id: current_client.try(:id))
    @payment_type.assign_attributes(permitted_attributes([current_user_role_group, @payment_type]))

    respond_to do |format|
      if @payment_type.save
        format.html { redirect_to admin_payment_types_path, notice: I18n.t("controller.payment_types.notice.created") }
        format.json { render json: @payment_type, status: :created }
      else
        format.html { render :new }
        format.json { render json: { errors: @payment_type.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_payment_type
    @payment_type = PaymentType.where(id: params[:id], booking_portal_client_id: current_client.try(:id)).first if params[:id].present?
  end

end